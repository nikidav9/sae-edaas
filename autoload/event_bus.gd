extends Node
## Глобальная шина событий.
##
## Единственный разрешённый способ связи между системами и UI.
## Правило: UI слушает сигналы и шлёт "запросы-намерения", но НЕ трогает
## game logic напрямую. Системы испускают "факты" о произошедшем.
##
## Соглашение об именах:
##   *_requested — намерение (обычно от UI/игрока), система может отклонить.
##   прошедшее время (day_passed, visitor_arrived) — свершившийся факт.

# --- Время / цикл дня ---
signal day_passed(day: int)
signal night_started(day: int)
## phase: DayNightSystem.Phase (int), progress: float [0..1] внутри фазы.
signal day_phase_changed(phase: int, progress: float)

# --- Визитёры ---
signal visitor_arrived(visitor: VisitorData)
signal visitor_dialogue_started(visitor: VisitorData)
signal visitor_decision_requested(visitor: VisitorData, options: Array[String])
signal visitor_resolved(visitor: VisitorData, choice: String)
signal visitor_true_nature_revealed(visitor: VisitorData, trait_id: int)

# --- Группа выживших / NPC ---
signal npc_recruited(npc: NPCData)
signal npc_lost(npc: NPCData, reason: String)
signal ability_unlocked(ability_id: String)

# --- Мораль / репутация ---
signal morale_changed(new_value: float, delta: float)
signal raider_reputation_changed(new_value: float, delta: float)

# --- Угрозы ---
signal noise_emitted(position: Vector2, loudness: float)
signal horde_spotted(horde_id: int, position: Vector2)
signal horde_approaching(horde_id: int, eta_days: int)
signal base_attacked(attacker_count: int)

# --- Ресурсы ---
signal resource_changed(resource_id: String, amount: int)
## Текст подсказки взаимодействия (пустая строка = скрыть).
signal interaction_prompt_changed(text: String)

# --- Постройки ---
signal build_requested(building_data: BuildingData, cell: Vector2i)
signal building_placed(building_data: BuildingData, cell: Vector2i)
signal building_construction_completed(building_id: StringName, cell: Vector2i)
signal building_destroyed(building_id: StringName, cell: Vector2i)
signal build_mode_entered()
signal build_mode_exited()

# --- Сохранения ---
signal save_completed(slot: int)
signal load_completed(slot: int)

# --- Игровой цикл ---
signal game_started()
signal game_over(reason: String)

# --- Игрок ---
signal player_damaged(amount: int, remaining_health: int)
signal player_died()

# --- Рейдеры ---
signal raid_incoming(raider_count: int)
signal raid_started(raider_count: int)
signal raid_ended(repelled: bool)

# --- Экспедиции ---
signal expedition_started(npc_ability_id: String)
signal expedition_completed(npc_ability_id: String, loot: Array)
signal expedition_failed(npc_ability_id: String, reason: String)

# --- Зомби / стада ---
## Новый стимул появился на карте (тип: StimulusSystem.StimulusType).
signal stimulus_emitted(stimulus_type: int, position: Vector2, strength: float)
## Зомби влился в стадо.
signal zombie_joined_herd(zombie_id: int, herd_id: int)
## Стадо достигло herd_min_size_for_redirect и стало полноценным.
signal herd_formed(herd_id: int, position: Vector2, size: int)
## Стадо перенаправлено на новую цель (игрок применил приманку/шум).
signal herd_redirected(herd_id: int, new_target: Vector2)
## Стадо распалось (все зомби погибли или вернулись в пул).
signal herd_dispersed(herd_id: int)

# --- Уведомления (мост к NotificationManager) ---
signal notification_requested(title: String, body: String, delay_seconds: int)
