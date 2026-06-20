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

# --- Сохранения ---
signal save_completed(slot: int)
signal load_completed(slot: int)

# --- Уведомления (мост к NotificationManager) ---
signal notification_requested(title: String, body: String, delay_seconds: int)
