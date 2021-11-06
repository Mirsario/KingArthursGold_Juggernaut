#include "IJuggernautState.as";

namespace Juggernaut
{
	class JuggernautStateDefault : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			
		}
		
		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}
			
			if (this.isKeyPressed(key_action1) && juggernaut.attacksDelayedUntil <= getGameTime()) {
				SetState(@this, @juggernaut, JuggernautStates::Charging);
			} else if (this.isKeyPressed(key_action2) && juggernaut.grabsDelayedUntil <= getGameTime()) {
				SetState(@this, @juggernaut, JuggernautStates::Grabbing);
			}
		}

		void UpdateSprite(CSprite@ this)
		{

		}
	}
}