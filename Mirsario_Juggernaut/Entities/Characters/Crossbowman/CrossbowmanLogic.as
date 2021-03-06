// Crossbowman logic

#include "CrossbowmanCommon.as"
#include "ThrowCommon.as"
#include "Knocked.as"
#include "HittersNew.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";

#include "KnightCommon.as";
#include "ParticleSparks.as";

const int FLETCH_COOLDOWN = 45;
const int fletch_num_arrows = 1;

void onInit(CBlob@ this) {
	CrossbowmanInfo crossbowman;
	this.set("crossbowmanInfo", @crossbowman);

	this.set_s8("chargeTime", 0);
	this.set_u8("state", Crossbowman::State::Ready);
	this.set_bool("hasArrow", false);
	this.set_f32("gib health", - 1.5f);
	this.Tag("player");
	this.Tag("flesh");

	 // centered on arrows
	 // this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	 // centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	 // no spinning
	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot arrow");
	this.addCommandID("pickup arrow");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	SetHelp(this, "help self hide", "crossbowman", "Hide	$KEY_S$", "", 1);

	 // add a command ID for each arrow type
	for (uint i = 0; i < arrowTypeNames.length; i++ ) {
		this.addCommandID("pick " + arrowTypeNames[i]);
	}
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player) {
	if (player !is null) {
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16, 16));
	}
}

void ManageBow(CBlob@ this, CrossbowmanInfo@ crossbowman, RunnerMoveVars@ moveVars) {
	CSprite@ sprite = this.getSprite();
	bool isMyPlayer = this.isMyPlayer();
	bool hasArrow = crossbowman.hasArrow;
	s8 chargeTime = crossbowman.chargeTime;
	u8 state = crossbowman.state;
	Vec2f pos = this.getPosition();
	
	bool mouseLeft = this.isKeyPressed(key_action1) && !this.hasTag("noLMB");
	bool mouseLeftDown = this.isKeyJustPressed(key_action1) && !this.hasTag("noLMB");
	bool mouseRight = this.isKeyPressed(key_action2) && !this.hasTag("noRMB");
	bool mouseRightDown = this.isKeyJustPressed(key_action2) && !this.hasTag("noRMB");

	if (isMyPlayer) {
		if ((getGameTime() + this.getNetworkID()) % 10 == 0) {
			hasArrow = hasArrows(this);

			if (!hasArrow) {
				 // set back to default
				for (uint i = 0; i < Crossbowman::ArrowType::Count; i++ ) {
					hasArrow = hasArrows(this, i);
					
					if (hasArrow) {
						crossbowman.arrowType = i;
						break;
					}
				}
			}
		}
		
		this.set_bool("hasArrow", hasArrow);
		this.Sync("hasArrow", false);

		crossbowman.stabDelay = 0;
	}

	if (state == Crossbowman::State::Ready) {
		if (mouseLeft) {
			moveVars.canVault = false;

			hasArrow = hasArrows(this);

			if (!hasArrow) {
				crossbowman.arrowType = Crossbowman::ArrowType::Normal;
				hasArrow = hasArrows(this);
			}
			if (isMyPlayer && mouseLeftDown) {
				this.set_bool("hasArrow", hasArrow);
				this.Sync("hasArrow", false);
			}
			
			if (!hasArrow) {
				if (mouseLeftDown) {
					if (isMyPlayer && !this.wasKeyPressed(key_action1) && !this.hasTag("noLMB")) {
						Sound::Play("Entities/Characters/Sounds/NoAmmo.ogg");
					}
					
					state = Crossbowman::State::Firing;
					crossbowman.stateTime = 10;
				}
			} else if (mouseLeftDown) {
				if (crossbowman.needsReload) {
					state = Crossbowman::State::Reloading;
					crossbowman.stateTime = Crossbowman::ReloadTime;
					this.getSprite().PlaySound("CrossbowCharge1.ogg");
				} else {
					state = Crossbowman::State::Firing;
					crossbowman.needsReload = true;
					crossbowman.stateTime = Crossbowman::PostFireDelay;
					ClientFire(this, chargeTime, hasArrow, crossbowman.arrowType);
				}
			}
		} else if (mouseRightDown) {
			state = Crossbowman::State::Stabbing;
			crossbowman.stateTime = 20;
			
			f32 angle = -((this.getAimPos() - pos).getAngleDegrees());
			
			if (angle < 0.0f) {
				angle += 360.0f;
			}
			
			Vec2f dir = Vec2f(1.0f, 0.0f).RotateBy(angle);
			crossbowman.attackDirection = dir;
			crossbowman.attackRotation = angle;
			crossbowman.dontHitMore = false;
			
			this.getSprite().PlaySound("KnifeStab.ogg");
		}
	} else if (state == Crossbowman::State::Firing) {
		crossbowman.stateTime--;
		
		if (crossbowman.stateTime <= 0) {
			state = Crossbowman::State::Ready;
		}
	} else if (state == Crossbowman::State::Reloading) {
		moveVars.canVault = false;
		moveVars.jumpFactor *= 0.25f;
		moveVars.walkFactor = 0.15f;
		
		crossbowman.stateTime--;
		
		if (crossbowman.stateTime <= 0) {
			crossbowman.needsReload = false;
			state = Crossbowman::State::Ready;
		}
	} else if (state == Crossbowman::State::Stabbing) {
		moveVars.canVault = false;
		moveVars.jumpFactor *= 0.33f;
		moveVars.walkFactor = 0.66f;
		
		if (getNet().isServer() && crossbowman.stateTime >= 5 && !crossbowman.dontHitMore) {
			 // Grab
			const float Range = 16.0f;

			Vec2f dir = crossbowman.attackDirection;
			Vec2f position = this.getPosition();
			HitInfo@ [] hitInfos;

			bool blobHit = getMap().getHitInfosFromArc(position, crossbowman.attackRotation, 30.0f, Range, this, @hitInfos);

			if (blobHit) {
				for (u32 i = 0;i < hitInfos.length;i ++ ) {
					if (hitInfos[i].blob is null) {
						continue;
					}
					
					CBlob@ blob = hitInfos[i].blob;
					
					if (blob.getTeamNum() == this.getTeamNum()) {
						continue;
					}

					if (blob.getConfig() == "knight") {
						if (blockAttack(blob, dir, 0.0f)) {
							Sound::Play("Entities/Characters/Knight/ShieldHit.ogg", pos);
							sparks(pos, - dir.Angle(), Maths::Max(10.0f * 0.05f, 1.0f));
							crossbowman.dontHitMore = true;
							break;
						} else {
							KnightInfo@ knight;
							
							if (this.get("knightInfo", @knight) && inMiddleOfAttack(knight.state)) {
								crossbowman.dontHitMore = true;
								break;
							}
						}
					}
					
					this.server_Hit(blob, this.getPosition(), dir, 1.0f, HittersNew::sword, false);
					crossbowman.dontHitMore = true;
					break;
				}
			}
		}
		
		crossbowman.stateTime--;
		
		if (crossbowman.stateTime <= 0) {
			state = Crossbowman::State::Ready;
		}
	}
	
	sprite.SetEmitSoundPaused(true);

	 // safe disable bomb light

	if (this.wasKeyPressed(key_action1) && !this.isKeyPressed(key_action1) && !this.hasTag("noLMB")) {
		const u8 type = crossbowman.arrowType;
		
		if (type == Crossbowman::ArrowType::Bomb) {
			BombFuseOff(this);
		}
	}

	 // my player!

	if (isMyPlayer) {
		 // set cursor

		if (!getHUD().hasButtons()) {
			int frame = 0;
			
			if (crossbowman.state == Crossbowman::State::Reloading) {
				frame = 8 - Maths::Round((f32(crossbowman.stateTime) / f32(Crossbowman::ReloadTime)) * 7.0f);
			} else {
				if (crossbowman.needsReload || crossbowman.state == Crossbowman::State::Stabbing) {
					frame = 0;
				} else {
					frame = 9;
				}
			}
			
			getHUD().SetCursorFrame(frame);
		}

		 // activate / throw

		if (this.isKeyJustPressed(key_action3)) {
			client_SendThrowOrActivateCommand(this);
		}

		 // pick up arrow

		if (crossbowman.fletchCooldown > 0) {
			crossbowman.fletchCooldown--;
		}
	}
	
	crossbowman.chargeTime = chargeTime;
	crossbowman.state = state;
	crossbowman.hasArrow = hasArrow;
}

void onTick(CBlob@ this) {
	CrossbowmanInfo@ crossbowman;
	
	if (!this.get("crossbowmanInfo", @crossbowman)) {
		return;
	}

	if (getKnocked(this) > 0) {
		crossbowman.state = 0;
		crossbowman.chargeTime = 0;
		return;
	}

	 // vvvvvvvvvvvvvv CLIENT - SIDE ONLY vvvvvvvvvvvvvvvvvvv

	 // if (!getNet().isClient()) return;

	 // if (this.isInInventory()) return;

	RunnerMoveVars@ moveVars;
	
	if (!this.get("moveVars", @moveVars)) {
		return;
	}
	
	ManageBow(this, crossbowman, moveVars);
}

bool canSend(CBlob@ this) {
	return(this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire(CBlob@ this, const s8 chargeTime, const bool hasArrow, const u8 arrowType) {
	 // time to fire!
	if (hasArrow && canSend(this)) {  // client - logic
		f32 arrowspeed = Crossbowman::ShootMaxVelocity;
		ShootArrow(this, this.getPosition() + Vec2f(0.0f, - 2.0f), this.getAimPos() + Vec2f(0.0f, - 2.0f), arrowspeed, arrowType);
	}
}

void ShootArrow(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed, const u8 arrowType) {
	if (canSend(this)) {
		 // player or bot
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		 // print("arrowspeed " + arrowspeed);
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);
		params.write_u8(arrowType);

		this.SendCommand(this.getCommandID("shoot arrow"), params);
	}
}

CBlob@ getPickupArrow(CBlob@ this) {
	CBlob@[] blobsInRadius;
	
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius)) {
		for (uint i = 0; i < blobsInRadius.length; i ++ ) {
			CBlob @b = blobsInRadius[i];
			
			if (b.getName() == "arrow") {
				return b;
			}
		}
	}
	
	return null;
}

bool canPickSpriteArrow(CBlob@ this, bool takeout) {
	CBlob@[] blobsInRadius;
	
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius)) {
		for (uint i = 0; i < blobsInRadius.length; i ++ ) {
			CBlob @b = blobsInRadius[i]; {
				CSprite@ sprite = b.getSprite();
				
				if (sprite.getSpriteLayer("arrow") !is null) {
					if (takeout) {
						sprite.RemoveSpriteLayer("arrow");
					}
					
					return true;
				}
			}
		}
	}
	
	return false;
}

CBlob@ CreateArrow(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel, u8 arrowType) {
	CBlob@ arrow = server_CreateBlobNoInit("arrow");
	
	if (arrow !is null) {
		 // fire arrow?
		arrow.set_u8("arrow type", arrowType);
		arrow.SetDamageOwnerPlayer(this.getPlayer());
		arrow.Init();

		arrow.IgnoreCollisionWhileOverlapped(this);
		arrow.server_setTeamNum(this.getTeamNum());
		arrow.setPosition(arrowPos);
		arrow.setVelocity(arrowVel);
	}
	
	return arrow;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params) {
	if (cmd == this.getCommandID("shoot arrow")) {
		Vec2f arrowPos = params.read_Vec2f();
		Vec2f arrowVel = params.read_Vec2f();
		u8 arrowType = params.read_u8();

		CrossbowmanInfo@ crossbowman;
		
		if (!this.get("crossbowmanInfo", @crossbowman)) {
			return;
		}
		
		crossbowman.arrowType = arrowType;

		 // return to normal arrow - server didnt have this synced
		if (!hasArrows(this, arrowType)) {
			return;
		}

		if (getNet().isServer()) {
			CreateArrow(this, arrowPos, arrowVel, arrowType);
		}
		
		this.getSprite().PlaySound("CrossbowFire4.ogg");
		this.TakeBlob(arrowTypeNames[ arrowType ], 1);

		crossbowman.fletchCooldown = FLETCH_COOLDOWN; // just don't allow shoot + make arrow
	}
	else if (cmd == this.getCommandID("pickup arrow")) {
		CBlob@ arrow = getPickupArrow(this);
		bool spriteArrow = canPickSpriteArrow(this, false);
		
		if (arrow !is null || spriteArrow) {
			if (arrow !is null) {
				CrossbowmanInfo@ crossbowman;
				
				if (!this.get("crossbowmanInfo", @crossbowman)) {
					return;
				}
				
				const u8 arrowType = crossbowman.arrowType;
				
				if (arrowType == Crossbowman::ArrowType::Bomb) {
					arrow.set_u16("follow", 0); // this is already synced, its in command.
					arrow.setPosition(this.getPosition());
					return;
				}
			}
			
			CBlob@ mat_arrows = server_CreateBlob("mat_arrows", this.getTeamNum(), this.getPosition());
			
			if (mat_arrows !is null) {
				mat_arrows.server_SetQuantity(fletch_num_arrows);
				mat_arrows.Tag("do not set materials");
				this.server_PutInInventory(mat_arrows);

				if (arrow !is null) {
					arrow.server_Die();
				}
				else {
					canPickSpriteArrow(this, true);
				}
			}
			
			this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
		}
	}
	else if (cmd == this.getCommandID("cycle")) { // from standardcontrols
		 // cycle arrows
		CrossbowmanInfo@ crossbowman;
		
		if (!this.get("crossbowmanInfo", @crossbowman)) {
			return;
		}
		
		u8 type = crossbowman.arrowType;

		int count = 0;
		
		while (count < arrowTypeNames.length) {
			type ++ ;
			count ++ ;
			
			if (type >= arrowTypeNames.length) {
				type = 0;
			}

			if (this.getBlobCount(arrowTypeNames[type]) > 0) {
				crossbowman.arrowType = type;
				
				if (this.isMyPlayer()) {
					Sound::Play("/CycleInventory.ogg");
				}
				
				break;
			}
		}
	}
	else {
		CrossbowmanInfo@ crossbowman;
		
		if (!this.get("crossbowmanInfo", @crossbowman)) {
			return;
		}
		
		for (uint i = 0; i < arrowTypeNames.length; i ++ ) {
			if (cmd == this.getCommandID("pick " + arrowTypeNames[i])) {
				crossbowman.arrowType = i;
				break;
			}
		}
	}
}

 // arrow pick menu
void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu) {
	if (arrowTypeNames.length == 0) {
		return;
	}
	
	this.ClearGridMenusExceptInventory();
	Vec2f pos(gridmenu.getUpperLeftPosition().x + 0.5f * (gridmenu.getLowerRightPosition().x - gridmenu.getUpperLeftPosition().x), gridmenu.getUpperLeftPosition().y - 32 * 1 - 2 * 24);
	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(arrowTypeNames.length, 2), "Current arrow");

	CrossbowmanInfo@ crossbowman;
	
	if (!this.get("crossbowmanInfo", @crossbowman)) {
		return;
	}
	
	const u8 arrowSel = crossbowman.arrowType;

	if (menu !is null) {
		menu.deleteAfterClick = false;

		for (uint i = 0; i < arrowTypeNames.length; i ++ ) {
			string matname = arrowTypeNames[i];
			CGridButton @button = menu.AddButton(arrowIcons[i], arrowNames[i], this.getCommandID("pick " + matname));

			if (button !is null) {
				bool enabled = this.getBlobCount(arrowTypeNames[i]) > 0;
				button.SetEnabled(enabled);
				button.selectOneOnClick = true;

				if (arrowSel == i) {
					button.SetSelected(1);
				}
			}
		}
	}
}

 // auto - switch to appropriate arrow when picked up
void onAddToInventory(CBlob@ this, CBlob@ blob) {
	string itemname = blob.getName();
	
	if (this.isMyPlayer()) {
		for (uint j = 0; j < arrowTypeNames.length; j ++ ) {
			if (itemname == arrowTypeNames[j]) {
				SetHelp(this, "help self action", "crossbowman", "$arrow$Fire arrow   $KEY_HOLD$$LMB$", "", 3);
				
				if (j > 0 && this.getInventory().getItemsCount() > 1) {
					SetHelp(this, "help inventory", "crossbowman", "$Help_Arrow1$$Swap$$Help_Arrow2$		$KEY_TAP$$KEY_F$", "", 2);
				}
				
				break;
			}
		}
	}
	
	CInventory@ inv = this.getInventory();
	
	if (inv.getItemsCount() == 0) {
		CrossbowmanInfo@ crossbowman;
		
		if (!this.get("crossbowmanInfo", @crossbowman)) {
			return;
		}
		
		for (uint i = 0; i < arrowTypeNames.length; i ++ ) {
			if (itemname == arrowTypeNames[i]) {
				crossbowman.arrowType = i;
			}
		}
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData) {
	if (customData == HittersNew::stab) {
		if (damage > 0.0f) {
			// fletch arrow
			if (hitBlob.hasTag("tree")) { // make arrow from tree
				if (getNet().isServer()) {
					CBlob@ mat_arrows = server_CreateBlob("mat_arrows", this.getTeamNum(), this.getPosition());
					
					if (mat_arrows !is null) {
						mat_arrows.server_SetQuantity(fletch_num_arrows);
						mat_arrows.Tag("do not set materials");
						this.server_PutInInventory(mat_arrows);
					}
				}
				
				this.getSprite().PlaySound("Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg");
			} else {
				this.getSprite().PlaySound("KnifeStab.ogg");
			}
		}

		if (blockAttack(hitBlob, velocity, 0.0f)) {
			this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
			SetKnocked(this, 30);
		}
	}
}

