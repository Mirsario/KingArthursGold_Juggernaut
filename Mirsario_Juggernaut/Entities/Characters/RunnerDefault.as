#include "RunnerCommon.as";
#include "Hitters.as";
#include "Knocked.as"
#include "FireCommon.as"
#include "Help.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");

	//default player minimap dot - not for migrants
	if (this.getName() != "migrant")
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	}

	this.set_s16(burn_duration , 130);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	setKnockable(this);
	
	this.addCommandID("playtaunt");
	this.set_u32("tauntTime",0);
}

void onTick(CBlob@ this)
{
	DoKnockedUpdate(this);
	const bool myPlayer=	this.isMyPlayer();
	if(myPlayer){
		CPlayer@ player=	this.getPlayer();
		if(player !is null)  {
			string playerName=	player.getUsername();
			u32 keyNum=-1;
			if(getControls().isKeyJustPressed(KEY_NUMPAD0)) {
				keyNum=0;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD1)) {
				keyNum=1;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD2)) {
				keyNum=2;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD3)) {
				keyNum=3;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD4)) {
				keyNum=4;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD5)) {
				keyNum=5;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD6)) {
				keyNum=6;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD7)) {
				keyNum=7;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD8)) {
				keyNum=8;
			}else if(getControls().isKeyJustPressed(KEY_NUMPAD9)) {
				keyNum=9;
			}else if(getControls().isKeyJustPressed(KEY_ADD)) {
				keyNum=10;
			}
			if(keyNum!=-1){
				CBitStream params;
				params.write_u32(keyNum);
				this.SendCommand(this.getCommandID("playtaunt"),params);
			}
		}
	}
	if(this.hasTag("playingTaunt")){
		u32 tauntTime=this.get_u32("tauntTime");
		if(getGameTime()>=tauntTime){
			this.getSprite().SetEmitSoundPaused(true);
			this.Untag("playingTaunt");
		}
	}
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().PlaySound("/Pickup.ogg");

	if (getNet().isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", "$" + attached.getName() + "$" + "Throw	$KEY_C$", "", 2);
	}

	// check if we picked a player - don't just take him out of the box
	/*if (attached.hasTag("player"))
	this.server_DetachFrom( attached ); CRASHES*/
}

// set the Z back
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetZ(0.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("migrant") || this.hasTag("dead");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd==this.getCommandID("playtaunt") && getNet().isClient()) {
		CPlayer@ player = this.getPlayer();
		if(player !is null){
			string username=player.getUsername();
			u32 number=		params.read_u32();
			this.getSprite().SetEmitSound(username+"_"+number+".ogg");
			this.getSprite().RewindEmitSound();
			this.getSprite().SetEmitSoundPaused(false);
			u32 time=30;
			switch(number){
				case 0: time=40; break;
				case 1: time=120; break;
				case 2: time=100; break;
				case 3: time=95; break;
				case 4: time=105; break;
				case 5: time=138; break;
				case 6: time=69; break;
				case 7: time=105; break;
				case 8: time=40; break;
				case 9: time=53; break;
				case 10: time=86; break;
			}
			this.set_u32("tauntTime",getGameTime()+time);
			this.Tag("playingTaunt");
			//this.getSprite().PlaySound(username+"_"+number+".ogg",1.0f,1.0f);
		}
	}
}