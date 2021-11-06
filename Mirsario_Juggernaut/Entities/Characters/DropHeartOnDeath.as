
//random heart on death (default is 100% of the time for consistency + to reward murder)

#define SERVER_ONLY

void dropHeart(CBlob@ this)
{
	if (!this.hasTag("dropped heart")) //double check
	{
		CPlayer@ killer = this.getPlayerOfRecentDamage();
		CPlayer@ myplayer = this.getDamageOwnerPlayer();

		if (killer is null || ((myplayer !is null) && killer.getUsername() == myplayer.getUsername())) { return; }

		this.Tag("dropped heart");
		
		int amount=1;
		if(this.getConfig()=="juggernaut"){
			amount=3;
		}
		for(int i=0;i<amount;i++){
			CBlob@ heart=server_CreateBlob("heart",-1,this.getPosition()+Vec2f(XORRandom(10)-5,XORRandom(10)-5));
			if(heart !is null) {
				Vec2f vel(XORRandom(2)==0 ? -2.0 : 2.0f, -5.0f);
				heart.setVelocity(vel);
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.hasTag("switch class") || this.hasTag("dropped heart") || this.hasBlob("food", 1)) { return; }	//don't make a heart on change class, or if this has already run before or if had bread

	dropHeart(this);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
