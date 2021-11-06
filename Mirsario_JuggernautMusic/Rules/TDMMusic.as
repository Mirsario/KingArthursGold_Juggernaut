// Game Music
#include "ModPath.as";

const u32 NumTracks = 13;

const array<string> MusicList = {
	MUSIC_PATH + "/Music/BetweenLevels.ogg",
	MUSIC_PATH + "/Music/ByeByeAmericanPie.ogg",
	MUSIC_PATH + "/Music/HellKeep.ogg",
	MUSIC_PATH + "/Music/HidingTheSecrets.ogg",
	MUSIC_PATH + "/Music/ImpSong.ogg",
	MUSIC_PATH + "/Music/IntermissionFromDOOM.ogg",
	MUSIC_PATH + "/Music/IntoTheBeastsBelly.ogg",
	MUSIC_PATH + "/Music/KitchenAceAndTakingNames.ogg",
	MUSIC_PATH + "/Music/LetsKillAtWill.ogg",
	MUSIC_PATH + "/Music/OnTheHunt.ogg",
	MUSIC_PATH + "/Music/Sadistic.ogg",
	MUSIC_PATH + "/Music/ShawnsGotTheShotgun.ogg",
	MUSIC_PATH + "/Music/SmellsLikeBurningCorpse.ogg"
};

void onInit(CBlob@ this)
{
	this.addCommandID("setMusic");
	this.addCommandID("requestMusic");
	this.Tag("musicPlayer");

	if(getNet().isServer()) {
		this.set_s32("currentTrack", XORRandom(NumTracks));
		
		CBitStream stream;

		stream.write_s32(this.get_s32("currentTrack"));
		
		this.SendCommand(this.getCommandID("setMusic"), stream);
		return;
	}
	
	this.set_s32("currentTrack", -1);

	CPlayer@ player = getLocalPlayer();

	if(player !is null) {
		CBitStream stream;

		stream.write_u16(player.getNetworkID());
		
		this.SendCommand(this.getCommandID("requestMusic"), stream);
	}

	this.set_u32("nextMusicRequest", 0);

	CMixer@ mixer = getMixer();

	if(mixer is null) {
		return;
	}

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();

	if(mixer is null) {
		return;
	}

	if(s_gamemusic && s_musicvolume > 0.0f) {
		if(!this.get_bool("initialized game")) {
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	} else {
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}


void onCommand(CBlob@ this, u8 cmd, CBitStream@ stream)
{
	if(cmd == this.getCommandID("requestMusic")) {
		if(!getNet().isServer()) {
			return;
		}

		CPlayer@ player = getPlayerByNetworkId(stream.read_u16());

		if(player !is null) {
			CBitStream stream;
			
			stream.write_s32(this.get_s32("currentTrack"));

			this.server_SendCommandToPlayer(this.getCommandID("setMusic"), stream, player);
		}
	} else if(cmd == this.getCommandID("setMusic")) {
		this.set_s32("currentTrack", stream.read_s32());
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if(mixer is null) {
		return;
	}

	this.set_bool("initialized game", true);

	mixer.ResetMixer();

	for(int i = 0; i < MusicList.length(); i++) {
		mixer.AddTrack(MusicList[i], i);
	}
}

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if(mixer is null) {
		return;
	}

	s32 currentTrack = this.get_s32("currentTrack");

	if(currentTrack >= 0) {
		if(mixer.getPlayingCount() == 0) {
			mixer.FadeInRandom(currentTrack, 0.0f);
		}
	} else {
		mixer.FadeOutAll(0.0f, 1.0f);

		if(getGameTime() >= this.get_u32("nextMusicRequest")) {
			CPlayer@ player = getLocalPlayer();

			if(player !is null) {
				CBitStream stream;

				stream.write_u16(player.getNetworkID());

				this.SendCommand(this.getCommandID("requestMusic"), stream);
				this.set_u32("nextMusicRequest", getGameTime() + 30);
			}
		}
	}
}