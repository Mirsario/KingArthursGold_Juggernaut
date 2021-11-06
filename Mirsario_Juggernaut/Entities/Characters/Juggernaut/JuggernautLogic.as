// Juggernaut logic
#include "ThrowCommon.as"
#include "JuggernautCommon.as";
#include "KnightCommon.as";
#include "ShieldCommon.as";
#include "RunnerCommon.as";
#include "HittersNew.as";
#include "Help.as";
#include "Requirements.as";
#include "SplashWater.as"
#include "ParticleSparks.as";
#include "FireCommon.as";

//attacks limited to the one time per-actor before reset.
void ActorLimitSetup(CBlob@ this)
{
	u16[] networkIDs;

	this.set("LimitedActors", networkIDs);
}

bool HasHitActor(CBlob@ this, CBlob@ actor)
{
	u16[]@networkIDs;

	this.get("LimitedActors", @networkIDs);

	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 HitActorCount(CBlob@ this)
{
	u16[]@networkIDs;

	this.get("LimitedActors", @networkIDs);

	return networkIDs.length;
}

void AddActorLimit(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void ClearActorLimit(CBlob@ this)
{
	this.clear("LimitedActors");
}

void SetState(CBlob@ this, JuggernautInfo@ juggernaut, JuggernautStates state, bool reset = true)
{
	SetState2(this, @juggernaut, state, reset);
}
//Yes, really.
void SetState2(CBlob@ this, JuggernautInfo@ juggernaut, u8 state, bool reset = true)
{
	if (!reset && juggernaut.state == state) {
		return;
	}

	juggernaut.prevState = juggernaut.state;
	juggernaut.state = state;
	juggernaut.stateStartTime = getGameTime();

	if (juggernaut.state >= 0 && juggernaut.state < states.length) {
		states[juggernaut.state].OnActivate(this);
	}
}

void onInit(CBlob@ this)
{
	this.addCommandID("syncState");
	this.addCommandID("grabbedSomeone");

	SetupJuggernautStates();

	this.Tag("juggernaut");
	this.Tag("cantEatFood");
	this.Tag("cantChangeClass");

	JuggernautInfo juggernaut;

	juggernaut.attacksDelayedUntil = 0;
	juggernaut.grabsDelayedUntil = 0;

	SetState(this, @juggernaut, JuggernautStates::Default);

	juggernaut.normalSprite = true;
	juggernaut.tileDestructionLimiter = 0;

	this.set("JuggernautInfo", @juggernaut);

	this.set_f32("gib health", 0.0f);
	this.set_s16(burn_duration, 360);

	ActorLimitSetup(this);

	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.Tag("player");
	this.Tag("flesh");

	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";

	this.set_string("grabbedEnemy", "knight");

	int playerCount = getPlayerCount();
	int heroCount = 0;
	int juggCount = 0;

	for (int i = 0; i < playerCount; i++) {
		CPlayer@ player = getPlayer(i);

		if (player.getTeamNum() == 0) {
			heroCount++;
		} else if (player.getTeamNum() == 1) {
			juggCount++;
		}
	}

	float scalePerPlayer = 1.0f / Maths::Lerp(8.0f, 6.0f, float(heroCount) / 15.0f);
	float healthScale = Maths::Min(1.0, (scalePerPlayer * Maths::Max(1.0f, float(heroCount - (juggCount - 1)))) / Maths::Max(1.0f, float(juggCount))) - ((juggCount - 1) * (scalePerPlayer / 2.0f));
	
	this.set_f32("healthScale", healthScale);
	this.set_f32("realInitialHealth", this.getInitialHealth() * healthScale);
	this.server_SetHealth(this.getInitialHealth() * healthScale);
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) {
		player.SetScoreboardVars("ScoreboardIcons.png", 3, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
	JuggernautInfo@ juggernaut;

	if (!this.get("JuggernautInfo", @juggernaut)) {
		return;
	}

	if (juggernaut.state >= 0 && juggernaut.state < states.length) {
		states[juggernaut.state].UpdateLogic(this);
	}

	if (this.isMyPlayer()) {
		getHUD().SetCursorFrame(0);
	}

	if (juggernaut.state != JuggernautStates::Charging && juggernaut.state != JuggernautStates::SwingingHammer && getNet().isServer()) {
		ClearActorLimit(this);
	}

	if (juggernaut.state != juggernaut.prevState) {
		if (getNet().isServer()) {
			//print("synchronizing state!");
			CBitStream stream;
			
			stream.write_u8(juggernaut.state);
			stream.write_u32(juggernaut.stateStartTime);

			this.SendCommand(this.getCommandID("syncState"), stream);
		}

		juggernaut.prevState = juggernaut.state;
	}
}

bool IsKnocked(CBlob@ blob)
{
	return blob.exists("knocked") && blob.get_u8("knocked") > 0;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ stream)
{
	JuggernautInfo@ juggernaut;

	if (!this.get("JuggernautInfo", @juggernaut)) {
		return;
	}
	
	if (cmd == this.getCommandID("syncState")) {
		if (!getNet().isServer()) {
			u8 state = stream.read_u8();

			SetState2(@this, @juggernaut, state, false);

			juggernaut.stateStartTime = stream.read_u32();
		}
	}
	
	if (cmd == this.getCommandID("grabbedSomeone")) {
		this.set_string("grabbedEnemy", stream.read_string());

		SetState(@this, @juggernaut, JuggernautStates::Holding);
		
		juggernaut.attacksDelayedUntil = stream.read_u32();

		if (getNet().isClient()) {
			this.getSprite().PlaySound("Gasp.ogg");

			CSpriteLayer@ victim = this.getSprite().getSpriteLayer("victim");

			if (victim !is null) {
				if (this.get_string("grabbedEnemy") == "crossbowman") {
					victim.ReloadSprite("CrossbowmanVictim.png", 64, 64, 0, 0);
				} else if (this.get_string("grabbedEnemy") == "trader") {
					victim.ReloadSprite("TraderVictim.png", 64, 64, 0, 0);
				} else {
					victim.ReloadSprite("KnightVictim.png", 64, 64, 0, 0);
				}
			}
		}
	}
}

float onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, float damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible")) {
		return 0.0f;
	}
	
	return damage;
}

void onDie(CBlob@ this)
{
	if (!getNet().isServer()) {
		return;
	}

	JuggernautInfo@ juggernaut;

	if (!this.get("JuggernautInfo", @juggernaut)) {
		return;
	}

	if (juggernaut.state == JuggernautStates::Holding) {
		CBlob@ blob = server_CreateBlob(this.get_string("grabbedEnemy"), 0, this.getPosition());

		if (blob !is null) {
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");

			if (point !is null) {
				CBlob@ attachedBlob = point.getOccupied();

				if (attachedBlob !is null) {
					CPlayer@ attachedPlayer = attachedBlob.getPlayer();

					string savedVictim;

					if (attachedPlayer !is null) {
						blob.server_SetPlayer(attachedPlayer);

						savedVictim = attachedPlayer.getUsername();
					} else {
						savedVictim = this.get_string("grabbedEnemy");
					}

					CBitStream params;

					params.write_u16(1);
					params.write_string(savedVictim + " was saved by the heroes!");

					CRules@ rules = getRules();

					rules.SendCommand(rules.getCommandID("broadcastMessage"), params);
				}
			}
		}
	}
}

//a little push forward
void pushForward(CBlob@ this, float normalForce, float pushingForce, float verticalForce)
{
	float facing_sign = this.isFacingLeft() ? -1.0f: 1.0f;
	bool pushing_in_facing_direction = (facing_sign < 0.0f && this.isKeyPressed(key_left)) || (facing_sign > 0.0f && this.isKeyPressed(key_right));
	float force = normalForce;

	if (pushing_in_facing_direction) {
		force = pushingForce;
	}

	this.AddForce(Vec2f(force * facing_sign, verticalForce));
}

// Blame Fuzzle.
bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible")) {
		return false;
	}

	// Don't hit carried items.
	if (b.isAttached()) {
		return false;
	}

	if (b.hasTag("dead")) {
		return true;
	}

	return b.getTeamNum() != this.getTeamNum();
}