--!strict
export type Value = number | Vector2 | Vector3 | UDim | UDim2 | Color3
export type Goals = { [string]: Value }
export type Curve = (number) -> number
export type Transition = {
	speed: number?,
	damper: number?,
	duration: number?,
	ease: Curve?,
	delay: number?,
	immediate: boolean?,
	positionThreshold: number?,
	velocityThreshold: number?,
	onComplete: (() -> ())?,
}
export type Cue = { at: number?, to: Goals, transition: Transition? }
export type Runtime = {
	step: (self: Runtime, dt: number) -> (),
	count: (self: Runtime) -> number,
	add: (self: Runtime, job: any) -> (),
	remove: (self: Runtime, job: any) -> (),
}
export type Motion = {
	to: (self: Motion, goals: Goals, transition: Transition?) -> Motion,
	spring: (self: Motion, goals: Goals, transition: Transition?) -> Motion,
	sequence: (self: Motion, cues: { Cue }, options: { onComplete: (() -> ())? }?) -> Motion,
	set: (self: Motion, goals: Goals) -> Motion,
	impulse: (self: Motion, forces: Goals) -> Motion,
	get: (self: Motion, property: string) -> Value,
	getVelocity: (self: Motion, property: string) -> Value,
	stop: (self: Motion) -> Motion,
	finish: (self: Motion) -> Motion,
	setReducedMotion: (self: Motion, enabled: boolean) -> (),
	destroy: (self: Motion) -> (),
}
export type MotionOptions = { runtime: Runtime?, onChange: ((string, Value) -> ())? }
export type CollectSpec = {
	from: Vector2 | Vector3,
	to: Vector2 | Vector3,
	count: number?,
	duration: number?,
	stagger: number?,
	arc: (Vector2 | Vector3)?,
	spread: (Vector2 | Vector3)?,
	ease: Curve?,
}
export type Emitter = {
	emit: (self: Emitter, spec: CollectSpec) -> number,
	clear: (self: Emitter) -> (),
	destroy: (self: Emitter) -> (),
	count: number,
}
export type CollectOptions = {
	runtime: Runtime?,
	capacity: number?,
	onAcquire: ((slot: number, origin: Vector2 | Vector3) -> ())?,
	onUpdate: (slot: number, position: Vector2 | Vector3, progress: number) -> (),
	onRelease: ((slot: number, arrived: boolean) -> ())?,
}
return {}
