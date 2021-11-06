#include "IJuggernautState.as";

namespace Juggernaut
{
	class JuggernautStateHolding : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}
			
			juggernaut.attacksDelayedUntil = getGameTime() + JuggernautVars::OnPickupAttackDelay;
		}

		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}
			
			//Holding someone or something
			if (juggernaut.attacksDelayedUntil > getGameTime()) {
				return;
			}
			
			if (this.isKeyJustPressed(key_action1)) {
				SetState(@this, @juggernaut, JuggernautStates::Throwing);
			} else if (this.isKeyJustPressed(key_action2) && this.get_string("grabbedEnemy") != "trader") {
				SetState(@this, @juggernaut, JuggernautStates::Fatality);
			}
		}
		
		void UpdateSprite(CSprite@ this)
		{

		}
	}
}