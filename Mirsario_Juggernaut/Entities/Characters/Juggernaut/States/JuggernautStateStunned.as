#include "IJuggernautState.as";

namespace Juggernaut
{
	class JuggernautStateStunned : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			
		}

		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;
			RunnerMoveVars@ moveVars;

			if (!this.get("JuggernautInfo", @juggernaut) || !this.get("moveVars", @moveVars)) {
				return;
			}

			moveVars.jumpFactor = 0.0f;
			moveVars.walkFactor = 0.0f;
			
			juggernaut.dontHitMore = false;
			juggernaut.stun--;

			if (juggernaut.stun <= 0) {
				SetState(@this, @juggernaut, JuggernautStates::Default);
			}
		}
		
		void UpdateSprite(CSprite@ this)
		{

		}
	}
}