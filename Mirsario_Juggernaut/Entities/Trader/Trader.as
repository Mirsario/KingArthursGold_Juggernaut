// Trader logic

#include "RunnerCommon.as"
#include "Help.as";

#include "Hitters.as";

#include "TraderWantedList.as";

//trader methods

//blob

string[] texts = { 
	"He's gonna be here soon!",
	"You'll save me, right?",
	"Who is that giant?",
	"I'm too young to die!",
	"This is a nightmare!"
};
string[] textsChased = { 
	"HELP ME!",
	"HE IS CHASING ME!",
	"SAVE ME!",
	"HE'S GOING TO KILL ME!",
	"Help! He's after me!",
	"I don't want to die!",
	"Don't hurt me!"
};
string[] textsWon = {
	"Thank god!",
	"You saved us!",
	"Hurray!",
	"Thank you!",
	"Thank you for saving me!",
	"Our heroes!",
	"It's dead! Finally!",
	"I am alive!"
};
string[] healTexts = { 
	"You're hurt? Take this.",
	"You're bleeding! Let me help you.",
	"I can help you.",
	"Use this! Kill that thing!"
};

string[] soundsDanger = { 
	"trader_scream_0.ogg",
	"trader_scream_1.ogg",
	"trader_scream_2.ogg"
};

void onInit(CBlob@ this) {
	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.set_f32("gib health", -1.5f);
	this.Tag("flesh");
	this.getBrain().server_SetActive(true);

	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	//this.getCurrentScript().runFlags |= Script::tick_moving;
	
	this.set_u32("nextTalk",getGameTime()+60+XORRandom(240));
	this.set_u32("nextHeart",0);
	
	this.addCommandID("traderChat");

	//EnsureWantedList();
}
void onTick(CBlob@ this) {
	if(getNet().isServer()) {
		if(!this.hasTag("dead")) {
			if(getGameTime()>=this.get_u32("nextTalk")) {
				this.set_u32("nextTalk",getGameTime()+40+XORRandom(160));
				
				CBlob@[] blobs;
				getBlobsByTag("juggernaut",blobs);
				string text = "";
				
				if(blobs.length()==0) {
					text = textsWon[XORRandom(textsWon.length())];
				} else {
					if(this.hasTag("chased")) {
						text = textsChased[XORRandom(textsChased.length())];
						this.getSprite().PlaySound(soundsDanger[XORRandom(soundsDanger.length())]);
					} else {
						text = texts[XORRandom(texts.length())];
					}
				}
				
				CBitStream stream;
				stream.write_string(text);
				this.SendCommand(this.getCommandID("traderChat"),stream);
			}
			if(getGameTime()>=this.get_u32("nextHeart")) {
				Vec2f pos = this.getPosition();
				int playersAmount = getPlayerCount();
				
				for(int i = 0;i<playersAmount;i++) {
					CPlayer@ player = getPlayer(i);
					CBlob@ blob = player.getBlob();
					
					if(blob !is null && blob.getTeamNum()==0 && blob.getHealth()!=blob.getInitialHealth()) {
						Vec2f blobPos = blob.getPosition();
						
						if((blobPos-pos).Length()<48.0f) {
							Vec2f direction = (blobPos-pos);
							direction.Normalize();
							CBlob@ heart = server_CreateBlob("heart",-1,this.getPosition());
							
							if(heart !is null) {
								heart.setVelocity(direction*3.0f);
							}
							
							this.set_u32("nextHeart",getGameTime()+300);
							this.set_u32("nextTalk",getGameTime()+60+XORRandom(240));
							
							CBitStream stream;
							stream.write_string(healTexts[XORRandom(healTexts.length())]);
							this.SendCommand(this.getCommandID("traderChat"),stream);
						}
					}
				}
			}
		}
	}
}

void onCommand(CBlob@ this,u8 cmd,CBitStream @stream) {
	if(cmd==this.getCommandID("traderChat")) {
		this.Chat(stream.read_string());
	}
}

void onReload(CSprite@ this) {
	this.getConsts().filename = this.getBlob().getSexNum() == 0 ?
								"Entities/Special/WAR/Trading/TraderMale.png" :
								"Entities/Special/WAR/Trading/TraderFemale.png";
}

void onGib(CSprite@ this) {
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	CParticle@ Gib1 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib2 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall");
	CParticle@ Gib3 = makeGibParticle("Entities/Special/WAR/Trading/TraderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "/BodyGibFall");
}

void onHealthChange(CBlob@ this, f32 oldHealth) {
	if (this.getHealth() < 1.0f && !this.hasTag("dead")) {
		this.Tag("dead");
		this.server_SetTimeToDie(20);
	}

	if (this.getHealth() < 0) {
		this.getSprite().Gib();
		this.server_Die();
		return;
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob) {
	if (byBlob.getTeamNum() != this.getTeamNum())
		return true;

	CBlob@[] blobsInRadius;
	
	if(this.getMap().getBlobsInRadius(this.getPosition(), 0.0f, @blobsInRadius)) {
		for (uint i = 0; i < blobsInRadius.length; i++) {
			CBlob @b = blobsInRadius[i];
			
			if(b.getName() == "tradingpost") {
				return false;
			}
		}
	}
	
	return true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob) {
	// dont collide with people
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData) {
	if(hitterBlob.getTeamNum()==this.getTeamNum()) {
		return 0.0f;
	}
	
	return damage;
}


//sprite/anim update

void onTick(CSprite@ this) {
	CBlob@ blob = this.getBlob();
	// set dead animations

	if (blob.hasTag("dead")) {
		if (!this.isAnimation("dead"))
			this.PlaySound("/TraderScream");

		this.SetAnimation("dead");

		if (blob.isOnGround()) {
			this.SetFrameIndex(0);
		}
		else {
			this.SetFrameIndex(1);
		}
		
		//this.getCurrentScript().runFlags |= Script::remove_after_this;

		return;
	}

	if (blob.hasTag("shoot wanted")) {
		this.SetAnimation("shoot");
		return;
	}

	// set animations
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	bool ended = this.isAnimationEnded();

	if ((blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right)) ||
			(blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down)))) {
		this.SetAnimation("walk");
	}
	else if (ended) {
		this.SetAnimation("default");
	}
}
