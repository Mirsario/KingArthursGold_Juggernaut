#include "IJuggernautState.as";
#include "SoundUtils.as";

namespace Juggernaut
{
	class JuggernautStateCharging : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			juggernaut.dontHitMore = false;
		}
		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;
			RunnerMoveVars@ moveVars;

			if (!this.get("JuggernautInfo", @juggernaut) || !this.get("moveVars", @moveVars)) {
				return;
			}

			//Charging hammer attack
			moveVars.jumpFactor *= JuggernautVars::AttackJumpFactor;
			moveVars.walkFactor *= JuggernautVars::AttackWalkFactor;

			Vec2f position = this.getPosition();
			float angle = -((this.getAimPos() - position).getAngleDegrees());

			if (angle < 0.0f) {
				angle += 360.0f;
			}

			Vec2f dir = Vec2f(1.0f, 0.0f).RotateBy(angle);
			juggernaut.attackDirection = dir;
			juggernaut.attackAimPos = this.getAimPos();
			juggernaut.attackRot = angle;
			angle = (this.getAimPos() - position).Angle();
			juggernaut.attackTrueRot = angle;
			juggernaut.wasFacingLeft = this.isFacingLeft();

			if (juggernaut.GetTime() >= JuggernautVars::ChargeTime) {
				SetState(@this, @juggernaut, JuggernautStates::SwingingHammer);
			}
		}
		void UpdateSprite(CSprite@ this)
		{

		}
	}
}