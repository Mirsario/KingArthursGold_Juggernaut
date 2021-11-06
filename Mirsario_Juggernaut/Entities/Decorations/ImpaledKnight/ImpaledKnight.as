
void onInit(CSprite@ this)
{
	Animation@ animation = this.getAnimation("default");
	if(animation is null) return;

	Vec2f pos=	this.getBlob().getPosition();
	this.animation.frame=	/*s32(pos.x+pos.y)%*/XORRandom(animation.getFramesCount());
	this.SetFacingLeft(XORRandom(2)==0);
}