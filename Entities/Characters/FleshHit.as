// Flesh hit

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Damage(damage, hitterBlob);
	// Gib if health below gibHealth
	f32 gibHealth = getGibHealth(this);

	if (this.getHealth() <= gibHealth)
	{
		if(this.hasTag("team0")){
			this.server_setTeamNum(0);
		}
		if(getNet().isClient()){
			Sound::Play("Gore.ogg",this.getPosition(),1.0f);
		}
		this.getSprite().Gib();
		this.server_Die();
	}

	return 0.0f; //done, we've used all the damage
}
void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency=this.getConfig()=="juggernaut" ? 4 : 5;
}
void onTick(CBlob@ this)
{
	//Bleeding
	if(getNet().isClient() && !this.hasTag("dead")){
		f32 health=			this.getHealth();
		f32 initialHealth=	this.getInitialHealth();
		if(this.getConfig()=="juggernaut") {
			initialHealth=	this.get_f32("realInitialHealth");
		}
		if(this.getConfig()=="juggernaut" && health<initialHealth/3){
			ParticleBloodSplat(this.getPosition()+Vec2f(XORRandom(15)-7,XORRandom(15)-7),false);
			if(XORRandom(5)==0){
				ParticleBloodSplat(this.getPosition()+Vec2f(XORRandom(10)-5,XORRandom(10)-5),true);
			}
		}else if(this.getConfig()!="juggernaut" && (health<initialHealth/4 || (initialHealth>0.5f && health<=0.5f))){
			ParticleBloodSplat(this.getPosition()+Vec2f(XORRandom(10)-5,XORRandom(10)-5),false);
		}
	}
}