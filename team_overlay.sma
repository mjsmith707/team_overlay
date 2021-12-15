/*
BSD 3-Clause License

Copyright (c) [year], [fullname]
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <amxmodx>
#include <hamsandwich>
#include <cstrike>

#define NAME "Team Overlay"
#define VERSION "1.1"
#define AUTHOR "Raven"

#define OVERLAY_BANNER "Team Status:^n"
#define MSG_MAXLEN 1024
#define NAME_MAXLEN 16

#define TASKID_OFFSET 0
#define OVERLAY_REFRESH 0.5
#define HUD_R 255
#define HUD_G 255
#define HUD_B 255
#define HUD_X 0.02
#define HUD_Y 0.25
#define HUD_EFFECT 0
#define HUD_FXTIME 0.02
#define HUD_HOLDTIME 5.0
#define HUD_FADEINTIME 0.1
#define HUD_FADEOUTTIME 0.2
#define HUD_CHANNEL -1

#define WEAPON_EMPTY 		"         "
#define WEAPON_EMPTY_LEN 10
#define WEAPON_SHIELD_NAME 	"Shield   "

#define ARMOR_NONE_NAME 	"        "
#define ARMOR_NONE_LEN 9
#define ARMOR_VEST_NAME 	"Kevlar  "
#define ARMOR_VESTHELM_NAME	"Kvlr+Hlm"
#define DEFUSER_NONE_NAME	"   "
#define DEFUSER_NONE_LEN 4
#define DEFUSER_ACTIVE_NAME	"Kit"

#define G_WEAPONS_LEN 33

new const g_weapon_names[G_WEAPONS_LEN][] =
{
	"         ",
	"P228     ",
	"UNUSED   ",
	"Scout    ",
	"HE       ",
	"XM1014   ",
	"C4       ",
	"MAC10    ",
	"AUG      ",
	"Smoke    ",
	"Dualies  ",
	"FiveSeven",
	"UMP45    ",
	"SG550    ",
	"GALIL    ",
	"FAMAS    ",
	"USP      ",
	"Glock    ",
	"AWP      ",
	"MP5      ",
	"M249     ",
	"M3       ",
	"M4A1     ",
	"TMP      ",
	"G3SG1    ",
	"Flashbang",
	"Deagle   ",
	"SG552    ",
	"AK47     ",
	"         ",
	"P90      ",
	"         ",
	"         "
};

new cvar_overlay_enabled;
new cvar_mp_freezetime;
new g_hud_sync_obj;

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn, "player", "on_roundstart_callback", 1);
	
	cvar_overlay_enabled = create_cvar("tmo_enable", "1", FCVAR_NONE, "Enable the team overlay");
	
	cvar_mp_freezetime = get_cvar_pointer("mp_freezetime");
	
	g_hud_sync_obj = CreateHudSyncObj();
}

public on_roundstart_callback(client_id) {	
	if (get_pcvar_num(cvar_overlay_enabled)) {
		new taskid = TASKID_OFFSET + client_id;
		remove_task(taskid);
		new params[1];
		params[0] = 0;
		new repeat = floatround ( float(get_pcvar_num(cvar_mp_freezetime)) / OVERLAY_REFRESH );
		set_task(OVERLAY_REFRESH, "show_overlay", taskid, params, 1, "a", repeat);
	}
}

public show_overlay(params[], client_id) {
	if (!is_user_alive(client_id)) {
		return;
	}
	
	static msg[MSG_MAXLEN];
	static name[NAME_MAXLEN];

	new CsTeams:client_team = cs_get_user_team(client_id);
	new g_max_players = get_maxplayers();
	new msg_len;
	new money;
	static weapon[WEAPON_EMPTY_LEN];
	static armor[ARMOR_NONE_LEN];
	new CsArmorType:armor_t;
	static defuser[DEFUSER_NONE_LEN];
	
	msg_len = formatex(msg, strlen(OVERLAY_BANNER), OVERLAY_BANNER);
	
	for (new id=1; id<=g_max_players; id++) {
		if (is_user_connected(id) && (cs_get_user_team(id) == client_team)) {
			get_user_name(id, name, NAME_MAXLEN);
			money = cs_get_user_money(id);
			weapon_to_string(cs_get_user_weapon(id), weapon);
			cs_get_user_armor(id, armor_t);
			armor_to_string(armor_t, armor);
			defuser_to_string(cs_get_user_defuse(id), defuser);
			
			// name: money | weapon | armor | kit
			msg_len += format(msg[msg_len], MSG_MAXLEN - msg_len, "%-15s: $%-5d | %s | %s | %s^n", name, money, weapon, armor, defuser);
		}
	}

	set_hudmessage(HUD_R, HUD_G, HUD_B, HUD_X, HUD_Y, HUD_EFFECT, HUD_FXTIME, HUD_HOLDTIME, HUD_FADEINTIME, HUD_FADEOUTTIME, HUD_CHANNEL);
	ShowSyncHudMsg(client_id, g_hud_sync_obj, msg);
}

public weapon_to_string(csw_id, buff[WEAPON_EMPTY_LEN]) {
	if (csw_id >= G_WEAPONS_LEN) {
		switch (csw_id) {
			case 99:
				copy(buff, WEAPON_EMPTY_LEN, WEAPON_SHIELD_NAME);
			default:
				copy(buff, WEAPON_EMPTY_LEN, WEAPON_EMPTY);
		}
	} else {
		copy(buff, WEAPON_EMPTY_LEN, g_weapon_names[csw_id]);
	}
}

public armor_to_string(CsArmorType:armor_type, buff[ARMOR_NONE_LEN]) {
	switch (armor_type) {
		case CS_ARMOR_NONE:
			copy(buff, ARMOR_NONE_LEN, ARMOR_NONE_NAME);
		case CS_ARMOR_KEVLAR:
			copy(buff, ARMOR_NONE_LEN, ARMOR_VEST_NAME);
		case CS_ARMOR_VESTHELM:
			copy(buff, ARMOR_NONE_LEN, ARMOR_VESTHELM_NAME);
		default:
			copy(buff, ARMOR_NONE_LEN, ARMOR_NONE_NAME);
	}
}

public defuser_to_string(defuser_id, buff[DEFUSER_NONE_LEN]) {
	switch (defuser_id) {
		case 0:
			copy(buff, DEFUSER_NONE_LEN, DEFUSER_NONE_NAME);
		case 1:
			copy(buff, DEFUSER_NONE_LEN, DEFUSER_ACTIVE_NAME);
	}
}
