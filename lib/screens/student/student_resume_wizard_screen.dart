import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import 'career_ui.dart';

// ─── МОДЕЛЬ ОПЫТА РАБОТЫ ─────────────────────────────────────────────────────
class _WorkExp {
  String company    = '';
  String position   = '';
  String periodFrom = '';
  String periodTo   = '';
  String description= '';
  bool   current    = false;

  Map<String, dynamic> toJson() => {
    'company': company,
    'position': position,
    'from': periodFrom,
    'to': current ? 'по настоящее время' : periodTo,
    'description': description,
    'current': current,
  };
}

// ─── МОДЕЛЬ ОБРАЗОВАНИЯ ───────────────────────────────────────────────────────
class _Education {
  String institution = '';
  String specialization = '';
  String year = '';
  String level = 'Среднее профессиональное';

  Map<String, dynamic> toJson() => {
    'institution': institution,
    'specialization': specialization,
    'year': year,
    'level': level,
  };
}

// ─── МАСТЕР СОЗДАНИЯ РЕЗЮМЕ ───────────────────────────────────────────────────
class StudentResumeWizardScreen extends StatefulWidget {
  const StudentResumeWizardScreen({super.key, this.resumeId});
  final int? resumeId;

  @override
  State<StudentResumeWizardScreen> createState() => _StudentResumeWizardScreenState();
}

class _StudentResumeWizardScreenState extends State<StudentResumeWizardScreen> {
  final ApiClient _api = AppSession.apiClient;
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;
  bool _loading = false;
  bool _saving = false;

  // Данные по специальностям + вопросам
  List<SpecialtyWithQuestions> _specialties = const [];
  SpecialtyWithQuestions? _selectedSpecialty;
  final Map<int, String> _specialtyAnswers = {};

  // ─── Данные формы ────────────────────────────────────────────────────────
  // Шаг 1 — Специальность и должность
  final _positionCtrl = TextEditingController();

  // Шаг 2 — Личные данные
  final _lastNameCtrl  = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _midNameCtrl   = TextEditingController();
  String _gender = '';
  final _birthDateCtrl = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _telegramCtrl  = TextEditingController();
  final _vkCtrl        = TextEditingController();

  // Шаг 3 — Зарплата и условия
  final _salaryCtrl = TextEditingController();
  final _employmentTypes = <String>{};
  final _scheduleTypes   = <String>{};

  // Шаг 4 — Опыт работы
  final List<_WorkExp> _workExperiences = [];

  // Шаг 5 — Образование
  final List<_Education> _educations = [_Education()]; // минимум 1

  // Шаг 6 — Навыки
  final List<String> _skills = [];
  final _skillInputCtrl = TextEditingController();

  // Шаг 7 — О себе
  final _aboutCtrl = TextEditingController();

  // Шаг 8 — Вопросы специальности (динамический, только если есть вопросы)

  bool _isPublished = false;

  static const _employmentOptions = [
    'Полная занятость',
    'Частичная занятость',
    'Проектная работа',
    'Волонтёрство',
    'Стажировка',
  ];

  static const _scheduleOptions = [
    'Полный день',
    'Сменный график',
    'Гибкий график',
    'Удалённая работа',
    'Вахтовый метод',
  ];

  static const _educationLevels = [
    'Среднее профессиональное',
    'Бакалавриат',
    'Магистратура',
    'Специалитет',
    'Аспирантура',
    'Другое',
  ];

  bool get _hasSpecialtyQuestions =>
      _selectedSpecialty != null && _selectedSpecialty!.questions.isNotEmpty;

  int get _totalSteps => _hasSpecialtyQuestions ? 9 : 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _specialties = await _api.fetchSpecialtiesForResume();

      // Если редактируем — загружаем данные
      if (widget.resumeId != null) {
        final existing = await _api.fetchStudentResumeById(widget.resumeId!);
        if (existing != null) _fillFromExisting(existing);
      }
    } catch (e) {
      debugPrint('WizardScreen load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _fillFromExisting(StudentResumeFullItem item) {
    _positionCtrl.text  = item.desiredPosition;
    _lastNameCtrl.text  = item.lastName;
    _firstNameCtrl.text = item.firstName;
    _midNameCtrl.text   = item.middleName;
    _gender             = item.gender;
    _birthDateCtrl.text = item.birthDate ?? '';
    _cityCtrl.text      = item.city;
    _phoneCtrl.text     = item.phone;
    _emailCtrl.text     = item.email;
    _telegramCtrl.text  = item.telegram;
    _vkCtrl.text        = item.vk;
    _salaryCtrl.text    = item.desiredSalary?.toString() ?? '';
    _aboutCtrl.text     = item.about;
    _isPublished        = item.isPublished;

    _employmentTypes
      ..clear()
      ..addAll(item.employmentType);
    _scheduleTypes
      ..clear()
      ..addAll(item.schedule);

    for (final exp in item.workExperience) {
      final w = _WorkExp()
        ..company     = (exp['company'] ?? '').toString()
        ..position    = (exp['position'] ?? '').toString()
        ..periodFrom  = (exp['from'] ?? '').toString()
        ..periodTo    = (exp['to'] ?? '').toString()
        ..description = (exp['description'] ?? '').toString()
        ..current     = exp['current'] == true;
      _workExperiences.add(w);
    }

    _educations.clear();
    for (final edu in item.education) {
      final e = _Education()
        ..institution    = (edu['institution'] ?? '').toString()
        ..specialization = (edu['specialization'] ?? '').toString()
        ..year           = (edu['year'] ?? '').toString()
        ..level          = (edu['level'] ?? 'Среднее профессиональное').toString();
      _educations.add(e);
    }
    if (_educations.isEmpty) _educations.add(_Education());

    _skills
      ..clear()
      ..addAll(item.skills);

    // Специальность
    if (item.specialtyId != null) {
      try {
        _selectedSpecialty = _specialties.firstWhere((s) => s.id == item.specialtyId);
      } catch (_) {}
    }

    // Ответы на вопросы специальности
    final ans = item.specialtyAnswers;
    ans.forEach((key, val) {
      final id = int.tryParse(key);
      if (id != null) _specialtyAnswers[id] = val.toString();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final answers = <String, String>{};
      _specialtyAnswers.forEach((k, v) => answers[k.toString()] = v);

      final data = {
        'specialty_id'      : _selectedSpecialty?.id,
        'last_name'         : _lastNameCtrl.text.trim(),
        'first_name'        : _firstNameCtrl.text.trim(),
        'middle_name'       : _midNameCtrl.text.trim(),
        'gender'            : _gender,
        'birth_date'        : _birthDateCtrl.text.trim().isNotEmpty ? _birthDateCtrl.text.trim() : null,
        'city'              : _cityCtrl.text.trim(),
        'phone'             : _phoneCtrl.text.trim(),
        'email'             : _emailCtrl.text.trim(),
        'telegram'          : _telegramCtrl.text.trim(),
        'vk'                : _vkCtrl.text.trim(),
        'desired_position'  : _positionCtrl.text.trim(),
        'desired_salary'    : int.tryParse(_salaryCtrl.text.trim()),
        'employment_type'   : _employmentTypes.toList(),
        'schedule'          : _scheduleTypes.toList(),
        'work_experience'   : _workExperiences.map((e) => e.toJson()).toList(),
        'education'         : _educations.map((e) => e.toJson()).toList(),
        'skills'            : _skills,
        'about'             : _aboutCtrl.text.trim(),
        'languages'         : [],
        'portfolio_links'   : [],
        'specialty_answers' : answers,
        'is_published'      : _isPublished ? 1 : 0,
      };

      if (widget.resumeId == null) {
        await _api.createStudentResumeFull(data);
      } else {
        await _api.updateStudentResumeFull(widget.resumeId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _positionCtrl.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _midNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _telegramCtrl.dispose();
    _vkCtrl.dispose();
    _salaryCtrl.dispose();
    _aboutCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Создание резюме')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final steps = _buildStepTitles();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.resumeId == null ? 'Создание резюме' : 'Редактирование резюме'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Прогресс
          _buildProgressHeader(steps),

          // Страницы
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildPages(),
            ),
          ),

          // Нижняя навигация
          _buildBottomNav(),
        ],
      ),
    );
  }

  List<String> _buildStepTitles() {
    final steps = [
      'Специальность',
      'Личные данные',
      'Условия',
      'Опыт работы',
      'Образование',
      'Навыки',
      'О себе',
      'Финал',
    ];
    if (_hasSpecialtyQuestions) {
      steps.insert(steps.length - 1, _selectedSpecialty!.shortTitle.isNotEmpty
          ? _selectedSpecialty!.shortTitle
          : 'Специфика');
    }
    return steps;
  }

  Widget _buildProgressHeader(List<String> steps) {
    return Container(
      color: const Color(0xFF4A90E2),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Шаги (точки)
          Row(
            children: List.generate(_totalSteps, (i) {
              final done    = i < _currentStep;
              final current = i == _currentStep;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: done || current
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Шаг ${_currentStep + 1} из $_totalSteps',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
              ),
              Text(
                steps[_currentStep],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[
      _buildStep1_Specialty(),
      _buildStep2_PersonalData(),
      _buildStep3_Conditions(),
      _buildStep4_WorkExperience(),
      _buildStep5_Education(),
      _buildStep6_Skills(),
      _buildStep7_About(),
    ];
    if (_hasSpecialtyQuestions) {
      pages.add(_buildStepSpecialtyQuestions());
    }
    pages.add(_buildStepFinal());
    return pages;
  }

  Widget _buildBottomNav() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A90E2)),
                  foregroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Назад'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saving ? null : _nextStep,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                isLast ? 'Сохранить резюме' : 'Далее',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ШАГ 1: Специальность и должность ────────────────────────────────────
  Widget _buildStep1_Specialty() {
    return _StepContainer(
      title: 'Специальность и должность',
      subtitle: 'Выберите специальность и укажите желаемую должность',
      child: Column(
        children: [
          // Желаемая должность
          _WizardField(
            controller: _positionCtrl,
            label: 'Желаемая должность *',
            hint: 'Например: Frontend-разработчик',
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 16),

          // Специальность из БД
          if (_specialties.isEmpty)
            const _InfoCard(
              icon: Icons.school_outlined,
              text: 'Специальности не найдены. Укажите должность выше и продолжите',
            )
          else ...[
            const _SectionLabel(text: 'Ваша специальность (по программе обучения)'),
            const SizedBox(height: 8),
            ..._specialties.map((spec) {
              final selected = _selectedSpecialty?.id == spec.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSpecialty = selected ? null : spec;
                  if (!selected && _positionCtrl.text.isEmpty) {
                    _positionCtrl.text = spec.title;
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF4A90E2).withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? const Color(0xFF4A90E2) : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF4A90E2).withOpacity(0.12)
                              : const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: selected ? const Color(0xFF4A90E2) : Colors.black38,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spec.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? const Color(0xFF4A90E2) : Colors.black87,
                              ),
                            ),
                            if (spec.code.isNotEmpty)
                              Text(
                                spec.code,
                                style: const TextStyle(fontSize: 12, color: Colors.black45),
                              ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF4A90E2)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── ШАГ 2: Личные данные ─────────────────────────────────────────────────
  Widget _buildStep2_PersonalData() {
    return _StepContainer(
      title: 'Личные данные',
      subtitle: 'Укажите ваше имя и контактную информацию',
      child: Column(
        children: [
          _WizardField(controller: _lastNameCtrl,  label: 'Фамилия *',   icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _WizardField(controller: _firstNameCtrl, label: 'Имя *',       icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _WizardField(controller: _midNameCtrl,   label: 'Отчество',    icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),

          // Пол
          const _SectionLabel(text: 'Пол'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ToggleChip(
                label: 'Мужской',
                icon: Icons.male_rounded,
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = _gender == 'male' ? '' : 'male'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ToggleChip(
                label: 'Женский',
                icon: Icons.female_rounded,
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = _gender == 'female' ? '' : 'female'),
              )),
            ],
          ),
          const SizedBox(height: 14),

          // Дата рождения
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                locale: const Locale('ru'),
              );
              if (picked != null) {
                setState(() {
                  _birthDateCtrl.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                });
              }
            },
            child: AbsorbPointer(
              child: _WizardField(
                controller: _birthDateCtrl,
                label: 'Дата рождения',
                icon: Icons.cake_outlined,
                hint: 'ГГГГ-ММ-ДД',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _WizardField(controller: _cityCtrl, label: 'Город проживания', icon: Icons.location_on_outlined),
          const SizedBox(height: 14),

          const _SectionLabel(text: 'Контакты'),
          const SizedBox(height: 8),
          _WizardField(
            controller: _phoneCtrl,
            label: 'Телефон',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            hint: '+7 (999) 000-00-00',
          ),
          const SizedBox(height: 10),
          _WizardField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress,
            hint: 'example@mail.ru',
          ),
          const SizedBox(height: 10),
          _WizardField(controller: _telegramCtrl, label: 'Telegram', icon: Icons.telegram, hint: '@username'),
          const SizedBox(height: 10),
          _WizardField(controller: _vkCtrl, label: 'ВКонтакте', icon: Icons.person_pin_outlined, hint: 'https://vk.com/id...'),
        ],
      ),
    );
  }

  // ─── ШАГ 3: Условия ───────────────────────────────────────────────────────
  Widget _buildStep3_Conditions() {
    return _StepContainer(
      title: 'Условия работы',
      subtitle: 'Укажите желаемую зарплату, тип занятости и график',
      child: Column(
        children: [
          _WizardField(
            controller: _salaryCtrl,
            label: 'Желаемая зарплата (руб.)',
            icon: Icons.payments_outlined,
            inputType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: 'Например: 50000',
          ),
          const SizedBox(height: 16),

          const _SectionLabel(text: 'Тип занятости (можно несколько)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _employmentOptions.map((opt) {
              final sel = _employmentTypes.contains(opt);
              return _ToggleChip(
                label: opt,
                selected: sel,
                onTap: () => setState(() =>
                sel ? _employmentTypes.remove(opt) : _employmentTypes.add(opt)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const _SectionLabel(text: 'График работы (можно несколько)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scheduleOptions.map((opt) {
              final sel = _scheduleTypes.contains(opt);
              return _ToggleChip(
                label: opt,
                selected: sel,
                onTap: () => setState(() =>
                sel ? _scheduleTypes.remove(opt) : _scheduleTypes.add(opt)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── ШАГ 4: Опыт работы ──────────────────────────────────────────────────
  Widget _buildStep4_WorkExperience() {
    return _StepContainer(
      title: 'Опыт работы',
      subtitle: 'Добавьте места работы, стажировки и практику',
      child: Column(
        children: [
          if (_workExperiences.isEmpty)
            const _InfoCard(
              icon: Icons.work_history_outlined,
              text: 'Опыт работы не указан. Можно пропустить этот шаг, нажав «Далее»',
            ),
          ..._workExperiences.asMap().entries.map((e) => _WorkExpCard(
            exp: e.value,
            index: e.key,
            onRemove: () => setState(() => _workExperiences.removeAt(e.key)),
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _workExperiences.add(_WorkExp())),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Добавить место работы'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A90E2),
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ШАГ 5: Образование ───────────────────────────────────────────────────
  Widget _buildStep5_Education() {
    return _StepContainer(
      title: 'Образование',
      subtitle: 'Укажите учебные заведения, которые вы окончили или учитесь',
      child: Column(
        children: [
          ..._educations.asMap().entries.map((e) => _EducationCard(
            edu: e.value,
            index: e.key,
            levels: _educationLevels,
            onRemove: _educations.length > 1
                ? () => setState(() => _educations.removeAt(e.key))
                : null,
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _educations.add(_Education())),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Добавить учебное заведение'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A90E2),
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ШАГ 6: Навыки ────────────────────────────────────────────────────────
  Widget _buildStep6_Skills() {
    // Предложенные навыки на основе специальности
    final suggestions = _getSkillSuggestions();

    return _StepContainer(
      title: 'Ключевые навыки',
      subtitle: 'Добавьте профессиональные навыки и компетенции',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ввод навыка
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputCtrl,
                  decoration: InputDecoration(
                    labelText: 'Навык',
                    prefixIcon: const Icon(Icons.star_outline_rounded, color: Color(0xFF4A90E2)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: 'Введите навык...',
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && !_skills.contains(val.trim())) {
                      setState(() {
                        _skills.add(val.trim());
                        _skillInputCtrl.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final val = _skillInputCtrl.text.trim();
                  if (val.isNotEmpty && !_skills.contains(val)) {
                    setState(() {
                      _skills.add(val);
                      _skillInputCtrl.clear();
                    });
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Добавленные навыки
          if (_skills.isNotEmpty) ...[
            const _SectionLabel(text: 'Добавленные навыки'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) => Chip(
                label: Text(skill),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => setState(() => _skills.remove(skill)),
                backgroundColor: const Color(0xFFE3F2FD),
                labelStyle: const TextStyle(color: Color(0xFF4A90E2)),
                side: const BorderSide(color: Color(0xFF4A90E2)),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Предложения
          if (suggestions.isNotEmpty) ...[
            const _SectionLabel(text: 'Популярные навыки по вашей специальности'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .where((s) => !_skills.contains(s))
                  .map((s) => GestureDetector(
                onTap: () => setState(() => _skills.add(s)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(s, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getSkillSuggestions() {
    if (_selectedSpecialty == null) return const [];
    final title = _selectedSpecialty!.title.toLowerCase();

    if (title.contains('информ') || title.contains('программ') || title.contains('веб') || title.contains('it')) {
      return ['Python', 'JavaScript', 'HTML/CSS', 'SQL', 'Git', 'Linux', 'Docker', 'React', 'Flutter'];
    }
    if (title.contains('экономик') || title.contains('бухгалт') || title.contains('финанс')) {
      return ['1C Бухгалтерия', 'Excel', 'Финансовый анализ', 'Налоговый учёт', 'МСФО'];
    }
    if (title.contains('строит') || title.contains('архитект')) {
      return ['AutoCAD', 'ArchiCAD', 'Revit', 'SketchUp', 'Сметное дело'];
    }
    if (title.contains('менеджмент') || title.contains('управлен')) {
      return ['Управление проектами', 'Agile', 'Scrum', 'MS Project', 'Переговоры'];
    }
    return ['MS Office', 'Работа в команде', 'Коммуникабельность', 'Обучаемость', 'Ответственность'];
  }

  // ─── ШАГ 7: О себе ────────────────────────────────────────────────────────
  Widget _buildStep7_About() {
    return _StepContainer(
      title: 'О себе',
      subtitle: 'Расскажите о себе, своих целях и достижениях',
      child: Column(
        children: [
          TextField(
            controller: _aboutCtrl,
            maxLines: 8,
            maxLength: 1500,
            decoration: InputDecoration(
              labelText: 'О себе',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 130),
                child: Icon(Icons.person_outline_rounded, color: Color(0xFF4A90E2)),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText:
              'Напишите несколько предложений о себе, своих целях, '
                  'сильных сторонах и том, чего хотите достичь...',
            ),
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.lightbulb_outline_rounded,
            text: 'Совет: укажите ваши главные достижения, профессиональные цели и почему вы подходите для этой работы',
          ),
        ],
      ),
    );
  }

  // ─── ШАГ: Вопросы специальности ──────────────────────────────────────────
  Widget _buildStepSpecialtyQuestions() {
    final questions = _selectedSpecialty?.questions ?? [];
    return _StepContainer(
      title: 'Профессиональные вопросы',
      subtitle: 'Ответьте на вопросы по вашей специальности — это поможет найти лучшую работу',
      child: Column(
        children: questions.map((q) {
          final answer = _specialtyAnswers[q.id] ?? '';

          if (q.fieldType == 'select' && q.fieldOptions.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                value: answer.isEmpty ? null : answer,
                decoration: InputDecoration(
                  labelText: q.question + (q.isRequired ? ' *' : ''),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: q.fieldOptions
                    .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                    .toList(),
                onChanged: (v) => setState(() => _specialtyAnswers[q.id] = v ?? ''),
              ),
            );
          }

          if (q.fieldType == 'multiselect' && q.fieldOptions.isNotEmpty) {
            final selected = answer.isNotEmpty
                ? (jsonDecode(answer) as List).map((e) => e.toString()).toSet()
                : <String>{};
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question + (q.isRequired ? ' *' : ''),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: q.fieldOptions.map((opt) {
                      final sel = selected.contains(opt);
                      return _ToggleChip(
                        label: opt,
                        selected: sel,
                        onTap: () {
                          setState(() {
                            if (sel) selected.remove(opt); else selected.add(opt);
                            _specialtyAnswers[q.id] = jsonEncode(selected.toList());
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          // text / textarea / number / date
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              maxLines: q.fieldType == 'textarea' ? 4 : 1,
              keyboardType: q.fieldType == 'number' ? TextInputType.number : TextInputType.text,
              onChanged: (v) => _specialtyAnswers[q.id] = v,
              controller: TextEditingController(text: answer)
                ..selection = TextSelection.collapsed(offset: answer.length),
              decoration: InputDecoration(
                labelText: q.question + (q.isRequired ? ' *' : ''),
                alignLabelWithHint: q.fieldType == 'textarea',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── ШАГ ФИНАЛЬНЫЙ: Публикация ───────────────────────────────────────────
  Widget _buildStepFinal() {
    final hasName = _lastNameCtrl.text.trim().isNotEmpty || _firstNameCtrl.text.trim().isNotEmpty;
    final hasPosition = _positionCtrl.text.trim().isNotEmpty;

    return _StepContainer(
      title: 'Готово!',
      subtitle: 'Проверьте данные и сохраните резюме',
      child: Column(
        children: [
          // Превью резюме
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 30, color: Color(0xFF4A90E2)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasName
                                ? [_lastNameCtrl.text, _firstNameCtrl.text, _midNameCtrl.text]
                                .where((s) => s.isNotEmpty).join(' ')
                                : 'Имя не указано',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            hasPosition ? _positionCtrl.text : 'Должность не указана',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _PreviewRow(icon: Icons.location_on_outlined, text: _cityCtrl.text.isNotEmpty ? _cityCtrl.text : '—'),
                _PreviewRow(icon: Icons.phone_outlined, text: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '—'),
                _PreviewRow(icon: Icons.email_outlined, text: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '—'),
                if (_salaryCtrl.text.isNotEmpty)
                  _PreviewRow(icon: Icons.payments_outlined, text: '${_salaryCtrl.text} руб.'),
                if (_selectedSpecialty != null)
                  _PreviewRow(icon: Icons.school_outlined, text: _selectedSpecialty!.title),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _skills.take(6).map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11.5)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFE3F2FD),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Публикация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Опубликовать резюме',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text(
                        'Резюме станет доступно в карьерном центре',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublished,
                  activeColor: const Color(0xFF4A90E2),
                  onChanged: (v) => setState(() => _isPublished = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ─────────────────────────────────────────────────

class _StepContainer extends StatelessWidget {
  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13.5)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _WizardField extends StatelessWidget {
  const _WizardField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.inputType,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black54),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A90E2) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF4A90E2) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF4A90E2), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── КАРТОЧКА ОПЫТА РАБОТЫ ────────────────────────────────────────────────────
class _WorkExpCard extends StatefulWidget {
  const _WorkExpCard({
    required this.exp,
    required this.index,
    required this.onRemove,
  });
  final _WorkExp exp;
  final int index;
  final VoidCallback onRemove;

  @override
  State<_WorkExpCard> createState() => _WorkExpCardState();
}

class _WorkExpCardState extends State<_WorkExpCard> {
  late final TextEditingController _companyCtrl;
  late final TextEditingController _posCtrl;
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _companyCtrl = TextEditingController(text: widget.exp.company);
    _posCtrl     = TextEditingController(text: widget.exp.position);
    _fromCtrl    = TextEditingController(text: widget.exp.periodFrom);
    _toCtrl      = TextEditingController(text: widget.exp.periodTo);
    _descCtrl    = TextEditingController(text: widget.exp.description);
  }

  @override
  void dispose() {
    _companyCtrl.dispose(); _posCtrl.dispose();
    _fromCtrl.dispose(); _toCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline_rounded, color: Color(0xFF4A90E2), size: 20),
              const SizedBox(width: 8),
              Text('Место работы ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: widget.onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _companyCtrl,
            onChanged: (v) => widget.exp.company = v,
            decoration: const InputDecoration(
              labelText: 'Компания / организация',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _posCtrl,
            onChanged: (v) => widget.exp.position = v,
            decoration: const InputDecoration(
              labelText: 'Должность',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _fromCtrl,
              onChanged: (v) => widget.exp.periodFrom = v,
              decoration: const InputDecoration(
                labelText: 'С (год-месяц)',
                hintText: '2022-09',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: widget.exp.current
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('по настоящее время', style: TextStyle(color: Colors.black54)),
            )
                : TextField(
              controller: _toCtrl,
              onChanged: (v) => widget.exp.periodTo = v,
              decoration: const InputDecoration(
                labelText: 'По (год-месяц)',
                hintText: '2024-05',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )),
          ]),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: widget.exp.current,
            contentPadding: EdgeInsets.zero,
            title: const Text('По настоящее время', style: TextStyle(fontSize: 13)),
            onChanged: (v) => setState(() => widget.exp.current = v ?? false),
          ),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            onChanged: (v) => widget.exp.description = v,
            decoration: const InputDecoration(
              labelText: 'Обязанности и достижения',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── КАРТОЧКА ОБРАЗОВАНИЯ ─────────────────────────────────────────────────────
class _EducationCard extends StatefulWidget {
  const _EducationCard({
    required this.edu,
    required this.index,
    required this.levels,
    required this.onRemove,
  });
  final _Education edu;
  final int index;
  final List<String> levels;
  final VoidCallback? onRemove;

  @override
  State<_EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<_EducationCard> {
  late final TextEditingController _instCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _yearCtrl;

  @override
  void initState() {
    super.initState();
    _instCtrl = TextEditingController(text: widget.edu.institution);
    _specCtrl = TextEditingController(text: widget.edu.specialization);
    _yearCtrl = TextEditingController(text: widget.edu.year);
  }

  @override
  void dispose() {
    _instCtrl.dispose(); _specCtrl.dispose(); _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: Color(0xFF4A90E2), size: 20),
              const SizedBox(width: 8),
              Text('Образование ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _instCtrl,
            onChanged: (v) => widget.edu.institution = v,
            decoration: const InputDecoration(
              labelText: 'Учебное заведение',
              hintText: 'Название университета или колледжа',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          // Уровень образования
          DropdownButtonFormField<String>(
            value: widget.edu.level,
            decoration: const InputDecoration(
              labelText: 'Уровень образования',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: widget.levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => widget.edu.level = v ?? widget.edu.level),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _specCtrl,
            onChanged: (v) => widget.edu.specialization = v,
            decoration: const InputDecoration(
              labelText: 'Специальность / факультет',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => widget.edu.year = v,
            decoration: const InputDecoration(
              labelText: 'Год окончания',
              hintText: '2025',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty || text == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
