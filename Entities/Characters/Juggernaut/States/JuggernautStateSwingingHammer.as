#include "IJuggernautState.as";
#include "JuggernautCommon.as";
#include "JuggernautLogic.as";
#include "HittersNew.as";

namespace Juggernaut
{
	class JuggernautStateSwingingHammer : IJuggernautState
	{
		void OnActivate(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;

			if (!this.get("JuggernautInfo", @juggernaut)) {
				return;
			}

			juggernaut.dontHitMore = false;

			if (getNet().isClient()) {
				Sound::Play("/ArgLong", this.getPosition());
				
				PlaySoundRanged(this, "SwingHeavy", 4, 1.0f, 1.0f);
			}

			Vec2f force = juggernaut.attackDirection * this.getMass() * 3.0f;

			this.AddForce(force);
		}
		void UpdateLogic(CBlob@ this)
		{
			JuggernautInfo@ juggernaut;
			RunnerMoveVars@ moveVars;

			if (!this.get("JuggernautInfo", @juggernaut) || !this.get("moveVars", @moveVars)) {
				return;
			}

			//Attacking with the hammer
			moveVars.jumpFactor *= JuggernautVars::AttackJumpFactor;
			moveVars.walkFactor *= JuggernautVars::AttackWalkFactor;

			this.SetFacingLeft(juggernaut.wasFacingLeft);

			int tick = juggernaut.GetTime();

			if (tick >= JuggernautVars::AttackTime) {
				SetState(@this, @juggernaut, JuggernautStates::Default);

				juggernaut.dontHitMore = false;
				juggernaut.attacksDelayedUntil = getGameTime() + JuggernautVars::AttackDelay;
			} else if (tick < 12) {
				DoAttack(this, 2.0f, juggernaut, 100.0f, HittersNew::hammer, tick);
			}
		}
		void UpdateSprite(CSprite@ this)
		{

		}

		void DamageWall(CBlob@ this, CMap@ map, Vec2f pos) {
			if (pos.x < 0.0f || pos.x >= map.tilemapwidth * 8.0f || pos.y < 0.0f || pos.y >= map.tilemapheight * 8.0f) {
				return;
			}

			Tile tile = map.getTile(pos);

			if (map.isTileBackground(tile) && !map.isTileGroundBack(tile.type)) {
				tile.type = CMap::TileEnum::tile_empty;

				map.server_SetTile(pos, tile);
			}
		}

		void DoAttack(CBlob@ this, float damage, JuggernautInfo@ info, float arcDegrees, u8 type, int deltaInt)
		{
			float aimangle = -(info.attackDirection.Angle());

			if (aimangle < 0.0f) {
				aimangle += 360.0f;
			}

			float exact_aimangle = info.attackTrueRot;
			Vec2f aimPos = info.attackAimPos;
			//get the actual aim angle
			Vec2f blobPos = this.getPosition();
			Vec2f vel = this.getVelocity();
			Vec2f thinghy(1, 0);

			thinghy.RotateBy(aimangle);

			Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
			vel.Normalize();

			float attack_distance = JuggernautVars::AttackDistance;

			float radius = this.getRadius();
			CMap@ map = this.getMap();
			bool dontHitMore = false;
			bool dontHitMoreMap = false;
			bool hasHitBlob = false;
			bool hasHitMap = false;

			if (getNet().isServer() && (blobPos - aimPos).Length() <= attack_distance * 1.5f) {
				DamageWall(this, map, aimPos);
			}

			// this gathers HitInfo objects which contain this or tile hit information
			HitInfo@ [] hitInfos;

			if (map.getHitInfosFromArc(pos, aimangle, arcDegrees, radius + attack_distance, this, @hitInfos)) {
				//HitInfo objects are sorted,first come closest hits
				for (uint i = 0; i < hitInfos.length; i++) {
					HitInfo@ hi = hitInfos[i];
					CBlob@ b = hi.blob;

					if (b !is null && !dontHitMore && deltaInt <= JuggernautVars::AttackTime - 9) // this
					{
						//big things block attacks
						const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

						if (!canHit(this, b)) {
							// no TK
							if (large) {
								dontHitMore = true;
							}

							continue;
						}

						if (HasHitActor(this, b)) {
							if (large) {
								dontHitMore = true;
							}

							continue;
						}

						AddActorLimit(this, b);

						if (!dontHitMore) {
							if (getNet().isServer()) {
								Vec2f velocity = b.getPosition() - pos;
								this.server_Hit(b, hi.hitpos, velocity, damage, type, true); // server_Hit() is server-side only
							}

							// end hitting if we hit something solid,don't if its flesh
							if (large) {
								dontHitMore = true;
							}
						}

						hasHitBlob = true;
					} else if (!dontHitMoreMap && (deltaInt == DELTA_BEGIN_ATTACK + 1)) { // hitmap
						Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
						Vec2f offset = (tpos - blobPos);
						float tileangle = offset.Angle();
						float dif = Maths::Abs(exact_aimangle - tileangle);

						if (dif > 180) {
							dif -= 360;
						}

						if (dif < -180) {
							dif += 360;
						}

						dif = Maths::Abs(dif);
						
						if (dif < 30.0f) {
							hasHitMap = true;

							if (!getNet().isServer()) {
								continue;
							}

							if (map.getSectorAtPosition(tpos, "no build") !is null) {
								continue;
							}

							TileType tile = map.getTile(hi.hitpos).type;

							if (!map.isTileBedrock(tile)) {
								map.server_DestroyTile(hi.hitpos, 1000.0f, this);
							}

							DamageWall(this, map, hi.hitpos + Vec2f( - 8, 0));
							DamageWall(this, map, hi.hitpos + Vec2f(8, 0));
							DamageWall(this, map, hi.hitpos + Vec2f(0, -8));
							DamageWall(this, map, hi.hitpos + Vec2f(0, 8));
						}
					}
				}

				if (hasHitMap && !hasHitBlob) {
					PlaySoundRanged(this, "HammerHit", 3, 1.0f, 1.0f);
				}
			}

			// destroy grass
			if (deltaInt != DELTA_BEGIN_ATTACK + 1) {
				return;
			}

			float tileSize = map.tilesize;
			int steps = Maths::Ceil(2 * radius / tileSize);
			int sign = this.isFacingLeft() ? -1 : 1;

			for (int y = 0; y < steps; y++) {
				for (int x = 0; x < steps; x++) {
					Vec2f tilePos = blobPos + Vec2f(x * tileSize * sign, y * tileSize);
					TileType tile = map.getTile(tilePos).type;

					if (!map.isTileGrass(tile)) {
						continue;
					}

					map.server_DestroyTile(tilePos, damage, this);

					if (damage <= 1.0f) {
						return;
					}
				}
			}
		}
	}
}