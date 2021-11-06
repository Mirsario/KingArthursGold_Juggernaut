shared void PlaySoundRanged(CBlob@ blob, string sound, int range, float volume, float pitch) {
	PlaySoundRanged(blob.getSprite(), sound, range, volume, pitch);
}
		
shared void PlaySoundRanged(CSprite@ sprite, string sound, int range, float volume, float pitch) {
	sprite.PlaySound(sound + (range > 1 ? formatInt(XORRandom(range - 1) + 1, "") + ".ogg": ".ogg"), volume, pitch);
}