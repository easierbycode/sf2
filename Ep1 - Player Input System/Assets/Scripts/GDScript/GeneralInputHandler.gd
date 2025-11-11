#GeneralInputHandler.gd
class_name GeneralInputHandler
extends CharacterBody2D

@export var _characterName : String
@export var _animPlayer : AnimationPlayer

var _waitAmountOfFrames : int = 10
var _elapsedWaitTime : float

var _isCrouching : bool = false
var _isAttacking : bool = false

var _gravity : float = 980.0
var _jump_force : float = -400.0
var _move_speed : float = 200.0

var _registeredKeyInputs : Array
var _moveSetDictionary : Dictionary

func _ready():
	SetupCharacterMoveSet(_characterName)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += _gravity * delta

	move_and_slide()

func _process(delta):
	if(_isAttacking): return
	TranslateInput()
	
	if(_registeredKeyInputs.size() > 0):
		_elapsedWaitTime += delta
		if(_elapsedWaitTime >= delta * _waitAmountOfFrames):
			PerformComboMove()

func TranslateInput():
	var key : String = ""
	
	# Actions that should be registered
	if Input.is_action_just_pressed("Punch"): key = "P"
	elif Input.is_action_just_pressed("Kick"): key = "K"
	elif Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = _jump_force
		key = "J"
	elif Input.is_action_just_pressed("Down"):
		key = "C"
	elif Input.is_action_just_released("Down"):
		key = "I"
	elif Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right"):
		key = "M"

	# Continuous movement
	if Input.is_action_pressed("Left"):
		velocity.x = -_move_speed
	elif Input.is_action_pressed("Right"):
		velocity.x = _move_speed
	else:
		velocity.x = 0

	if(key == ""): return

	PerformMove(key)
	_elapsedWaitTime = 0
	_registeredKeyInputs.append(key)

func PerformMove(key : String):
	if(!_moveSetDictionary.has([key]) or key == "M"):
		return
	
	var animNameKey : String = ReturnProperAnimName([key])
	if(animNameKey == _characterName + "_Idle_Anim" && _isCrouching): animNameKey = _characterName + "_Goes_Idle_Anim"
	elif(animNameKey == _characterName + "_Crouch_Anim" && !_isCrouching): animNameKey = _characterName + "_Goes_Crouch_Anim"
	
	if(_isCrouching):
		if(key == "K" or key == "P"):
			animNameKey = ReturnProperAnimName(["C", key])
	
	_animPlayer.play(animNameKey)

func perform_shoryuken():
	SetAttackingBool(true)
	velocity.y = _jump_force * 1.2
	_animPlayer.play(ReturnProperAnimName(["M", "C", "M", "P"]))
	_registeredKeyInputs.clear()
	await get_tree().create_timer(0.5).timeout
	SetAttackingBool(false)

func PerformComboMove():
	if "I" in _registeredKeyInputs:
		for release in range(len(_registeredKeyInputs) - 1, -1, -1):
			if _registeredKeyInputs[release] == "I":
				_registeredKeyInputs.remove_at(release)
	
	if(!_moveSetDictionary.has(_registeredKeyInputs)):
		_registeredKeyInputs.clear()
		return

	if _registeredKeyInputs == ["M", "C", "M", "P"]:
		perform_shoryuken()
		return
	
	_animPlayer.play(ReturnProperAnimName(_registeredKeyInputs))
	_registeredKeyInputs.clear()

func SetupCharacterMoveSet(characterName : String):
	_moveSetDictionary.clear()
	_moveSetDictionary.merge(CharacterMoveSet.generalMoves)
	_moveSetDictionary.merge(CharacterMoveSet.characters[characterName])

func SetAttackingBool(input : bool): _isAttacking = input if _isAttacking != input else _isAttacking

func SetCrouchingBool(input : bool): _isCrouching = input if _isCrouching != input else _isCrouching

func SetAfterTransitionAnimation():
	_isCrouching = false if !Input.is_action_pressed("Down") else true
	_animPlayer.play(ReturnProperAnimName(["C" if _isCrouching else "I"]))

func ReturnProperAnimName(keyInput : Array) -> String: return _characterName + "_" + _moveSetDictionary[keyInput] + "_Anim"
