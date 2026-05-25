<?php
/**
 * API: vk_pending_stories
 * GET    ?page=&limit=&status=  → list pending/approved/rejected
 * GET    ?id=
 * POST   ?action=approve  {id, selected_images:[url,...], title, description}
 *        ?action=reject   {id, reason}
 *        ?action=skip     {id}
 * DELETE ?id=
 */
require_once __DIR__ . '/../config.php';
sessionCheck();

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── GET ────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $st=$pdo->prepare("SELECT * FROM vk_pending_stories WHERE id=? LIMIT 1");
        $st->execute([(int)$_GET['id']]);
        $row=$st->fetch(PDO::FETCH_ASSOC);
        if(!$row) { http_response_code(404); json(['error'=>'Not found']); }
        if(!empty($row['images_json'])) $row['images'] = json_decode($row['images_json'],true)??[];
        json($row);
    }

    $page=max(1,(int)($_GET['page']??1));
    $limit=min(200,max(1,(int)($_GET['limit']??20)));
    $offset=($page-1)*$limit;

    $where=['1=1']; $params=[];
    $status = $_GET['status'] ?? 'pending';
    if($status !== 'all') { $where[]="status=?"; $params[]=$status; }

    $ws=implode(' AND ',$where);
    $tcnt=$pdo->prepare("SELECT COUNT(*) FROM vk_pending_stories WHERE $ws");
    $tcnt->execute($params); $total=(int)$tcnt->fetchColumn();

    $st=$pdo->prepare("SELECT * FROM vk_pending_stories WHERE $ws ORDER BY vk_date DESC, created_at DESC LIMIT $limit OFFSET $offset");
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    foreach($rows as &$r) {
        if(!empty($r['images_json'])) $r['images'] = json_decode($r['images_json'],true)??[];
    }

    // pending count for badge
    $pendingCnt = (int)$pdo->query("SELECT COUNT(*) FROM vk_pending_stories WHERE status='pending'")->fetchColumn();

    json(['data'=>$rows,'total'=>$total,'page'=>$page,'limit'=>$limit,'pages'=>ceil($total/$limit),'pending_count'=>$pendingCnt]);
}

// ── POST actions ───────────────────────────────────────────────────────────
if ($method === 'POST') {
    $d      = jsonBody();
    $action = $_GET['action'] ?? ($d['action'] ?? '');
    $id     = (int)($d['id'] ?? $_GET['id'] ?? 0);

    if (!$id) { http_response_code(400); json(['error'=>'id required']); }

    $check=$pdo->prepare("SELECT * FROM vk_pending_stories WHERE id=? LIMIT 1");
    $check->execute([$id]);
    $pending=$check->fetch(PDO::FETCH_ASSOC);
    if(!$pending) { http_response_code(404); json(['error'=>'Not found']); }

    // ── APPROVE → create story ────────────────────────────────────────────
    if ($action === 'approve') {
        $selectedImages = $d['selected_images'] ?? [];
        if(empty($selectedImages) && !empty($pending['images_json'])) {
            $allImages = json_decode($pending['images_json'],true)??[];
            $selectedImages = array_slice($allImages,0,1); // first image by default
        }

        $title       = trim($d['title']       ?? $pending['content'] ?? $pending['vk_text'] ?? 'История из ВКонтакте');
        $description = trim($d['description'] ?? $pending['content'] ?? $pending['vk_text'] ?? '');

        // Create story
        $storyData = [
            'title'        => mb_substr($title, 0, 200),
            'description'  => $description,
            'cover_image'  => $selectedImages[0] ?? '',
            'images_json'  => json_encode($selectedImages, JSON_UNESCAPED_UNICODE),
            'vk_post_id'   => $pending['vk_post_id'],
            'vk_post_url'  => $pending['vk_post_url'] ?? '',
            'is_published' => 1,
            'published_at' => date('Y-m-d H:i:s'),
        ];
        $cols = array_keys($storyData);
        $ph   = array_map(fn($c)=>":$c",$cols);
        $st   = $pdo->prepare("INSERT INTO stories (".implode(',',$cols).") VALUES (".implode(',',$ph).")");
        foreach($storyData as $k=>$v) $st->bindValue(":$k",$v);
        $st->execute();
        $storyId = (int)$pdo->lastInsertId();

        // Update pending status
        $pdo->prepare("UPDATE vk_pending_stories SET status='approved', story_id=?, moderated_at=NOW(), moderated_by=? WHERE id=?")
            ->execute([$storyId, $_SESSION['admin_id']??0, $id]);

        adminLog($pdo,'approve','vk_pending_stories',$id,"Одобрен VK-пост → история #{$storyId}");
        json(['status'=>'approved','story_id'=>$storyId]);
    }

    // ── REJECT ────────────────────────────────────────────────────────────
    if ($action === 'reject') {
        $reason = trim($d['reason'] ?? '');
        $pdo->prepare("UPDATE vk_pending_stories SET status='rejected', reject_reason=?, moderated_at=NOW(), moderated_by=? WHERE id=?")
            ->execute([$reason, $_SESSION['admin_id']??0, $id]);
        adminLog($pdo,'reject','vk_pending_stories',$id,"Отклонён VK-пост. Причина: $reason");
        json(['status'=>'rejected']);
    }

    // ── SKIP ──────────────────────────────────────────────────────────────
    if ($action === 'skip') {
        $pdo->prepare("UPDATE vk_pending_stories SET status='skipped', moderated_at=NOW(), moderated_by=? WHERE id=?")
            ->execute([$_SESSION['admin_id']??0, $id]);
        adminLog($pdo,'skip','vk_pending_stories',$id,'Пропущен VK-пост');
        json(['status'=>'skipped']);
    }

    http_response_code(400);
    json(['error'=>'Unknown action. Use: approve|reject|skip']);
}

// ── DELETE ─────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id=(int)($_GET['id']??0);
    if(!$id) { http_response_code(400); json(['error'=>'id required']); }
    $pdo->prepare("DELETE FROM vk_pending_stories WHERE id=?")->execute([$id]);
    adminLog($pdo,'delete','vk_pending_stories',$id,'Удалён VK-пост из очереди');
    http_response_code(204); exit;
}

http_response_code(405); json(['error'=>'Method Not Allowed']);