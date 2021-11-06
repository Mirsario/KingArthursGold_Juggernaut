#include "IJuggernautState.as"
#include "JuggernautStateDefault.as";
#include "JuggernautStateStunned.as";
#include "JuggernautStateCharging.as";
#include "JuggernautStateSwingingHammer.as";
#include "JuggernautStateGrabbing.as";
#include "JuggernautStateHolding.as";
#include "JuggernautStateThrowing.as";
#include "JuggernautStateFatality.as";

Juggernaut::IJuggernautState@[] states;

void SetupJuggernautStates()
{
	states.clear();
	
	states.insertLast(@Juggernaut::JuggernautStateDefault());
	states.insertLast(@Juggernaut::JuggernautStateStunned());
	states.insertLast(@Juggernaut::JuggernautStateCharging());
	states.insertLast(@Juggernaut::JuggernautStateSwingingHammer());
	states.insertLast(@Juggernaut::JuggernautStateGrabbing());
	states.insertLast(@Juggernaut::JuggernautStateHolding());
	states.insertLast(@Juggernaut::JuggernautStateThrowing());
	states.insertLast(@Juggernaut::JuggernautStateFatality());
}

enum JuggernautStates {
	Default = 0,
	Stunned,
	Charging,
	SwingingHammer,
	Grabbing,
	Holding,
	Throwing,
	Fatality
}

namespace JuggernautVars {
	const uint8 ChargeTime = 20;
	const uint8 AttackTime = 20;
	const uint8 GrabTime = 12;
	const uint8 ThrowTime = 12;
	const uint8 FatalityTime = 66;
	const uint8 AttackDelay = 10;
	const uint8 GrabDelay = 15;
	const uint8 GrabAttackDelay = 6;
	const uint8 ThrowDelay = 15;
	const uint8 OnPickupAttackDelay = 10;
	const float AttackJumpFactor = 0.375f;
	const float AttackWalkFactor = 0.4f;
	const float AttackDistance = 24.0f;
	const float GrabDistance = 14.0f;
}

shared class JuggernautInfo {
	u8 stun;
	u32 stateStartTime;
	//u32 stateTime;
	u32 attacksDelayedUntil;
	u32 grabsDelayedUntil;
	u8 tileDestructionLimiter;
	bool dontHitMore;
	bool superAttack;
	bool wasFacingLeft;
	Vec2f attackDirection;
	Vec2f attackAimPos;
	f32 attackTrueRot;
	f32 attackRot;

	u8 state;
	u8 prevState;
	Vec2f slash_direction;
	bool normalSprite;

	u32 GetTime()
	{
		return getGameTime() - stateStartTime;
	}
};