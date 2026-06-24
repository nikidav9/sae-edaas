extends Resource
class_name GameBalance
## Все баланс-числа в одном Resource. Логика систем читает значения отсюда,
## а не хардкодит их. Дизайнер тюнит баланс через .tres без правки кода.

@export_group("Визитёры")
## Минимальный/максимальный интервал между визитёрами (в днях).
@export var visitor_min_interval_days: int = 1
@export var visitor_max_interval_days: int = 3
## Базовые веса категорий в weighted random пуле (Type как индекс смысла).
@export var weight_friendly: float = 1.0
@export var weight_neutral: float = 1.0
@export var weight_hostile: float = 0.5
@export var weight_dilemma: float = 0.7
## Насколько раздутая репутация среди рейдеров поднимает вес враждебных
## (итоговый вес = weight_hostile * (1 + raider_reputation * этот множитель)).
@export var hostile_reputation_scaling: float = 3.0
## Время на принятие решения в диалоге визитёра (tension), секунды. 0 = без таймера.
@export var visitor_decision_seconds: float = 15.0

@export_group("Мораль")
@export var morale_loss_on_betrayal: float = 0.25
@export var morale_gain_on_rescue: float = 0.1
@export var manipulator_daily_morale_drain: float = 0.05

@export_group("Репутация рейдеров")
@export var reputation_gain_on_rob_trader: float = 0.15
@export var reputation_decay_per_day: float = 0.01

@export_group("Орды / шум")
## Громкость, выше которой орда меняет курс на источник шума.
@export var horde_noise_threshold: float = 0.5
## За сколько дней разведчик видит приближение орды заранее.
@export var scout_horde_warning_days: int = 2

@export_group("День / Ночь")
## Длительность одного игрового дня в реальных секундах.
@export var day_duration_seconds: float = 240.0
## Доля дня, приходящаяся на каждую фазу (сумма = 1.0).
## [dawn, day, dusk, night]
@export var phase_fractions: Array[float] = [0.1, 0.45, 0.1, 0.35]
## Цвета CanvasModulate для каждой фазы: dawn / day / dusk / night.
@export var phase_colors: Array[Color] = [
	Color(0.65, 0.55, 0.70),  # рассвет  — лиловый
	Color(1.00, 0.98, 0.95),  # день     — почти белый, чуть тёплый
	Color(0.85, 0.55, 0.30),  # закат    — оранжевый
	Color(0.13, 0.16, 0.28),  # ночь     — глубокий синий
]

@export_group("Оптимизация (mobile)")
## Жёсткий лимит активных зомби на экране (object pooling).
@export var max_active_zombies: int = 40
## Порог FPS, ниже которого орда переключается на MultiMeshInstance2D.
@export var multimesh_fps_threshold: int = 40

@export_group("Игрок")
@export var player_max_health: int = 100
@export var player_move_speed: float = 120.0
@export var player_attack_damage: int = 15
@export var player_attack_range: float = 48.0
@export var player_attack_cooldown: float = 0.8

@export_group("Рейдеры")
## Первый рейд происходит не раньше этого дня.
@export var raid_min_day: int = 5
## Промежуток между рейдами (дни), уменьшается по репутации.
@export var raid_interval_days: int = 4
## Базовое количество рейдеров.
@export var raid_base_count: int = 3
## Максимальное количество рейдеров в одном рейде.
@export var raid_max_count: int = 12
## Множитель числа рейдеров от raider_reputation.
@export var raid_reputation_scaling: float = 2.0
## Здоровье рейдера.
@export var raider_max_health: int = 50
## Урон от удара рейдера.
@export var raider_attack_damage: int = 12
## Скорость рейдера.
@export var raider_move_speed: float = 80.0

@export_group("Экспедиции")
## Базовая длительность экспедиции в днях.
@export var expedition_base_days: int = 2
## Бонус разведчика — на сколько дней короче экспедиция.
@export var expedition_scout_bonus_days: int = 1
## Минимальный/максимальный выход лута за экспедицию (единицы ресурсов).
@export var expedition_loot_min: int = 3
@export var expedition_loot_max: int = 8
## Шанс провала экспедиции (0.0 – 1.0).
@export var expedition_failure_chance: float = 0.1

@export_group("Зомби / стада")
## Радиус, в котором зомби замечает другого и присоединяется к его стаду.
@export var zombie_join_herd_radius: float = 120.0
## Скорость зомби в режиме блужданий (доля от move_speed).
@export var zombie_wander_speed: float = 25.0
## Скорость зомби, привлечённого стимулом.
@export var zombie_attracted_speed: float = 55.0
## Скорость стада.
@export var zombie_herd_speed: float = 40.0
## Потеря силы стимула в секунду.
@export var stimulus_decay_per_second: float = 0.15
## Минимальный размер стада для эффекта перенаправления.
@export var herd_min_size_for_redirect: int = 3
## Веса сил сплочения флокинга (cohesion/separation/alignment).
@export var flocking_cohesion_weight: float = 0.4
@export var flocking_separation_weight: float = 1.2
## Радиус избегания соседнего зомби в стаде.
@export var flocking_separation_radius: float = 36.0
@export var flocking_alignment_weight: float = 0.2
## Дистанция атаки зомби (пиксели).
@export var zombie_attack_range: float = 40.0
## Интервал атаки в секундах.
@export var zombie_attack_interval: float = 1.5
## Урон морали группы за каждую атаку зомби на базу.
@export var zombie_attack_morale_loss: float = 0.01
