#include "IJuggernautState.as";

namespace Juggernaut
{
	class JuggernautStateFatality : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			juggernaut.wasFacingLeft = this.isFacingLeft();
		}
		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;
			RunnerMoveVars@ moveVars;

			if (!this.get("JuggernautInfo", @juggernaut) || !this.get("moveVars", @moveVars)) {
				return;
			}

			Vec2f position = this.getPosition();

			moveVars.jumpFactor = 0.0f;
			moveVars.walkFactor = 0.0f;

			this.getShape().SetVelocity(Vec2f());

			if (!this.hasTag("invincible")) {
				this.Tag("invincible");
			}

			this.SetFacingLeft(juggernaut.wasFacingLeft);

			int tick = juggernaut.GetTime();

			if (tick == 46 && getNet().isServer()) {
				this.server_SetHealth(Maths::Min(this.getHealth() + 1.00f, this.get_f32("realInitialHealth")));

				AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

				if (point !is null) {
					CBlob@ attachedBlob = point.getOccupied();

					if (attachedBlob !is null) {
						CPlayer@ attachedPlayer = attachedBlob.getPlayer();

						if (attachedPlayer !is null) {
							CPlayer@ player = this.getPlayer();

							if (player !is null) {
								getRules().server_PlayerDie(attachedPlayer, player, HittersNew::stomp);
							} else {
								attachedBlob.server_Die();
							}
						} else {
							attachedBlob.server_Die();
						}
					}
				}
			}

			if (getNet().isClient()) {
				if (tick == 3) {
					Sound::Play("ArgShort.ogg", position, 1.0f);
				} else if (tick == 20) {
					Sound::Play("ArgLong.ogg", position, 1.0f);
				} else if (tick == 29) {
					ShakeScreen(6.0f, 5, this.getPosition());
					Sound::Play("FallOnGround.ogg", position, 0.4f);
				} else if (tick == 45) {
					ShakeScreen(25.0f, 6, this.getPosition());
				} else if (tick == 46) {
					Vec2f posOffset = position + Vec2f(this.isFacingLeft() ? -8 : 8, 3);

					ParticleBloodSplat(posOffset, true);

					for (int i = 0; i < 12; i++) {
						Vec2f vel = getRandomVelocity(float(XORRandom(360)), 1.0f + float(XORRandom(2)), 60.0f);

						makeGibParticle("mini_gibs.png", posOffset, vel, 0, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 20, "/BodyGibFall", 0);
					}
				} else if (tick == 48) {
					Sound::Play("Gore.ogg", position, 1.0f);
				}
			}

			if (tick >= JuggernautVars::FatalityTime) {
				SetState(@this, @juggernaut, JuggernautStates::Default);

				this.Untag("invincible");

				if (getNet().isServer()) {
					CBlob@ blob = server_CreateBlob(this.get_string("grabbedEnemy") == "crossbowman" ? "corpsestillcrossbowman": "corpsestill", 0, this.getPosition());
					blob.getSprite().SetFacingLeft(this.isFacingLeft());
				}
			}
		}
		void UpdateSprite(CSprite@ this)
		{

		}
	}
}
