#include "IJuggernautState.as";
#include "JuggernautCommon.as";
#include "JuggernautLogic.as";
#include "HittersNew.as";
#include "ShieldCommon.as";

namespace Juggernaut
{
	//Trying to grab a stunned enemy
	class JuggernautStateGrabbing : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			Vec2f position = this.getPosition();
			float angle = -((this.getAimPos() - position).getAngleDegrees());

			if (angle < 0.0f) {
				angle += 360.0f;
			}

			juggernaut.attackDirection = Vec2f(1.0f, 0.0f).RotateBy(angle);
			juggernaut.attackAimPos = this.getAimPos();
			juggernaut.attackRot = angle;
			angle = (this.getAimPos() - position).Angle();
			juggernaut.attackTrueRot = angle;

			juggernaut.wasFacingLeft = this.isFacingLeft();
			juggernaut.dontHitMore = false;

			if (getNet().isClient()) {
				Sound::Play("/ArgLong", position);
			}
		}
		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;
			RunnerMoveVars@ moveVars;

			if (!this.get("JuggernautInfo", @juggernaut) || !this.get("moveVars", @moveVars)) {
				return;
			}

			Vec2f position = this.getPosition();

			moveVars.jumpFactor *= JuggernautVars::AttackJumpFactor;
			moveVars.walkFactor *= JuggernautVars::AttackWalkFactor;

			this.SetFacingLeft(juggernaut.wasFacingLeft);

			if (juggernaut.GetTime() >= JuggernautVars::GrabTime) {
				SetState(@this, @juggernaut, JuggernautStates::Default);
				
				juggernaut.dontHitMore = false;
				juggernaut.grabsDelayedUntil = getGameTime() + JuggernautVars::GrabDelay;
				juggernaut.attacksDelayedUntil = getGameTime() + JuggernautVars::GrabAttackDelay;
				return;
			}
			
			if (!getNet().isServer() || juggernaut.GetTime() > (JuggernautVars::GrabTime / 4) * 3 || juggernaut.dontHitMore) {
				return;
			}

			//Grab
			const float range = 26.0f; //36.0f originally
			float angle = juggernaut.attackRot;
			Vec2f dir = juggernaut.attackDirection;

			Vec2f startPos = position;
			Vec2f endPos = startPos + (dir * range);

			HitInfo@ [] hitInfos;
			Vec2f hitPos;
			bool mapHit = getMap().rayCastSolid(startPos, endPos, hitPos);
			float length = (hitPos - startPos).Length();

			bool blobHit = getMap().getHitInfosFromRay(startPos, angle, length, this, @hitInfos);

			if (!getMap().getHitInfosFromArc(startPos, angle, 45.0f, length, this, @hitInfos)) {
				return;
			}
			
			for (u32 i = 0; i < hitInfos.length; i++) {
				HitInfo@ hitInfo = hitInfos[i];
				
				CBlob@ victim = hitInfo.blob;
				
				if (victim is null) {
					continue;
				}

				string victimType = victim.getConfig();

				if(victimType != "knight" && victimType != "crossbowman" && victimType != "trader") {
					continue;
				}

				if(victim.getTeamNum() == this.getTeamNum()) {
					continue;
				}

				if(victim.hasTag("dead")) {
					continue;
				}

				if (victimType == "knight") {
					if (blockAttack(victim, dir, 0.0f)) {
						Sound::Play("Entities/Characters/Knight/ShieldHit.ogg", position);
						sparks(position, -dir.Angle(), Maths::Max(10.0f * 0.05f, 1.0f));
						juggernaut.dontHitMore = true;
						break;
					} else {
						KnightInfo@ knight;

						if (victim.get("knightInfo", @knight) && inMiddleOfAttack(knight.state)) {
							juggernaut.dontHitMore = true;
							break;
						}
					}
				}

				if (victim.getHealth() <= 0.5f || IsKnocked(victim) || victimType == "trader") {
					CPlayer@ player = victim.getPlayer();

					if (player !is null) {
						CBlob@ newBlob = server_CreateBlob("playercontainer", 0, position);

						if (newBlob !is null) {
							newBlob.server_SetPlayer(player);

							AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

							this.server_AttachTo(newBlob, point);
							newBlob.server_setTeamNum(victim.getTeamNum());
							player.server_setTeamNum(victim.getTeamNum());
						}
					}

					victim.server_Die();

					SetState(@this, @juggernaut, JuggernautStates::Holding);

					CBitStream stream;
					stream.write_string(victim.getConfig());
					stream.write_u32(juggernaut.attacksDelayedUntil);
					this.SendCommand(this.getCommandID("grabbedSomeone"), stream);
				} else {
					this.server_Hit(victim, position, dir, 1.0f, HittersNew::flying, false);
				}

				juggernaut.dontHitMore = true;
				break;
			}
		}
		void UpdateSprite(CSprite@ this)
		{
			
		}
	}
}