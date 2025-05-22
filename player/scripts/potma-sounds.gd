class_name PotmaSounds extends Node3D;

@onready var walkSoundAudioStream: AudioStreamPlayer3D = $PotmaWalkAudioStream;
@onready var drinkSoundAudioStream: AudioStreamPlayer3D = $PotmaDrinkAudioStream;
@onready var runSoundAudioStream: AudioStreamPlayer3D = $PotmaRunAudioStream;
@onready var getHitSoundAudioStream: AudioStreamPlayer3D = $PotmaGetHitAudioStream;
@onready var jumpSoundAudioStream: AudioStreamPlayer3D = $PotmaJumpAudioStream;
@onready var megaJumpSoundAudioStream: AudioStreamPlayer3D = $PotmaMegaJumpAudioStream;