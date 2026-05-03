extends Node
class_name ShadowAnimalPhaseController

@onready var boss: ShadowBoss = get_parent() as ShadowBoss

func get_animal_idle_animation() -> String:
	return String(boss.animal_idle_animation)

func get_animal_transform_animation() -> String:
	return String(boss.animal_transform_animation)

func get_animal_slither_animation() -> String:
	return String(boss.animal_slither_animation)

func get_animal_ouroboros_animation() -> String:
	return String(boss.animal_ouroboros_animation)

func get_animal_idle_duration() -> float:
	return maxf(boss.animal_idle_duration, 0.0)

func get_animal_wolf_intro_animation() -> String:
	return String(boss.animal_wolf_intro_animation)

func get_animal_wolf_approach_animations() -> Array[String]:
	var animations: Array[String] = []
	for animation_name in boss.animal_wolf_approach_animations:
		animations.append(String(animation_name))
	return animations

func get_animal_wolf_attack_animations() -> Array[String]:
	var animations: Array[String] = []
	for animation_name in boss.animal_wolf_attack_animations:
		animations.append(String(animation_name))
	return animations

func get_animal_wolf_circle_radius() -> float:
	return maxf(boss.animal_wolf_circle_radius, 1.0)

func get_animal_attack_damage() -> float:
	return maxf(boss.animal_attack_damage, 0.0)

func get_animal_wolf_attack_damage() -> float:
	return maxf(boss.animal_wolf_attack_damage, 0.0)

func choose_animal_attack_type() -> String:
	var attack_types := ["snake", "wolf", "porcupine"]
	var attack_type: String = attack_types[boss._animal_attack_index % attack_types.size()]
	boss._animal_attack_index = (boss._animal_attack_index + 1) % attack_types.size()
	return attack_type

func get_animal_porcupine_wave_count() -> int:
	return maxi(boss.animal_porcupine_wave_count, 1)

func get_animal_porcupine_wave_size() -> int:
	return maxi(boss.animal_porcupine_wave_size, 1)

func get_animal_porcupine_wave_interval() -> float:
	return maxf(boss.animal_porcupine_wave_interval, 0.05)

func get_animal_porcupine_attack_duration() -> float:
	var minimum_duration := get_animal_porcupine_wave_interval() * float(maxi(get_animal_porcupine_wave_count() - 1, 0)) + 0.4
	return maxf(boss.animal_porcupine_attack_duration, minimum_duration)

func get_animal_porcupine_attack_damage() -> float:
	return maxf(boss.animal_porcupine_attack_damage, 0.0)
