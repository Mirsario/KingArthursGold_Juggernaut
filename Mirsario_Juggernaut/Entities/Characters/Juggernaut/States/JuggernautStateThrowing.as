#include "IJuggernautState.as";

namespace Juggernaut
{
	class JuggernautStateThrowing : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			Vec2f position = this.getPosition();

			juggernaut.attackTrueRot = (this.getAimPos() - position).Angle();
			juggernaut.dontHitMore = false;

			if (getNet().isClient()) {
				Sound::Play("/ArgLong", position);
			}

			if (getNet().isServer()) {
				float angle = -((this.getAimPos() - position).getAngleDegrees());

				if (angle < 0.0f) {
					angle += 360.0f;
				}

				string config = this.get_string("grabbedEnemy");
				Vec2f dir = Vec2f(1.0f, 0.0f).RotateBy(angle);
				CBlob@ blob = server_CreateBlob(config == "crossbowman" ? "corpsecrossbowman": (config == "trader" ? "corpsetrader": "corpseknight"), this.getTeamNum(), position);

				AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
				CBlob@ attachedBlob = point.getOccupied();

				if (attachedBlob !is null) {
					CPlayer@ attachedPlayer = attachedBlob.getPlayer();

					if (attachedPlayer !is null) {
						blob.server_SetPlayer(attachedPlayer);
					}

					attachedBlob.server_Die();
				}

				if (blob !is null) {
					blob.setVelocity(dir * 12.0f);

					if (this.getPlayer() !is null) {
						blob.SetDamageOwnerPlayer(this.getPlayer());
					}
				}

				this.Sync("extraSync", false);
			}
		}

		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			if (juggernaut.GetTime() >= JuggernautVars::ThrowTime) {
				SetState(@this, @juggernaut, JuggernautStates::Default);

				juggernaut.dontHitMore = false;
				juggernaut.attacksDelayedUntil = getGameTime() + JuggernautVars::ThrowDelay;
			}
		}
		
		void UpdateSprite(CSprite@ this)
		{

		}
	}
}