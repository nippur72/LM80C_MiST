// fkeys row
localparam [15:0] PS2_KEY_ESC           = 'h76;
localparam [15:0] PS2_KEY_F1            = 'h05;
localparam [15:0] PS2_KEY_F2            = 'h06;
localparam [15:0] PS2_KEY_F3            = 'h04;
localparam [15:0] PS2_KEY_F4            = 'h0c;
localparam [15:0] PS2_KEY_F5            = 'h03;
localparam [15:0] PS2_KEY_F6            = 'h0b;
localparam [15:0] PS2_KEY_F7            = 'h83;
localparam [15:0] PS2_KEY_F8            = 'h0a;
localparam [15:0] PS2_KEY_F9            = 'h01;
localparam [15:0] PS2_KEY_F10           = 'h09;
localparam [15:0] PS2_KEY_F11           = 'h78;
localparam [15:0] PS2_KEY_F12           = 'h07;

// number row
localparam [15:0] PS2_KEY_BACKTICK      = 'h0e;
localparam [15:0] PS2_KEY_1             = 'h16;
localparam [15:0] PS2_KEY_2             = 'h1e;
localparam [15:0] PS2_KEY_3             = 'h26;
localparam [15:0] PS2_KEY_4             = 'h25;
localparam [15:0] PS2_KEY_5             = 'h2e;
localparam [15:0] PS2_KEY_6             = 'h36;
localparam [15:0] PS2_KEY_7             = 'h3d;
localparam [15:0] PS2_KEY_8             = 'h3e;
localparam [15:0] PS2_KEY_9             = 'h46;
localparam [15:0] PS2_KEY_0             = 'h45;
localparam [15:0] PS2_KEY_MINUS         = 'h4e;
localparam [15:0] PS2_KEY_EQUAL         = 'h55;
localparam [15:0] PS2_KEY_BACKSPACE     = 'h66;

// qwerty row
localparam [15:0] PS2_KEY_TAB           = 'h0d;
localparam [15:0] PS2_KEY_Q             = 'h15;
localparam [15:0] PS2_KEY_W             = 'h1d;
localparam [15:0] PS2_KEY_E             = 'h24;
localparam [15:0] PS2_KEY_R             = 'h2d;
localparam [15:0] PS2_KEY_T             = 'h2c;
localparam [15:0] PS2_KEY_Y             = 'h35;
localparam [15:0] PS2_KEY_U             = 'h3c;
localparam [15:0] PS2_KEY_I             = 'h43;
localparam [15:0] PS2_KEY_O             = 'h44;
localparam [15:0] PS2_KEY_P             = 'h4d;
localparam [15:0] PS2_KEY_OPEN_BRACKET  = 'h54;
localparam [15:0] PS2_KEY_CLOSE_BRACKET = 'h5b;
localparam [15:0] PS2_KEY_RETURN        = 'h5a;

// asdfgh row
localparam [15:0] PS2_KEY_CAP_LOCK      = 'h58;
localparam [15:0] PS2_KEY_A             = 'h1c;
localparam [15:0] PS2_KEY_S             = 'h1b;
localparam [15:0] PS2_KEY_D             = 'h23;
localparam [15:0] PS2_KEY_F             = 'h2b;
localparam [15:0] PS2_KEY_G             = 'h34;
localparam [15:0] PS2_KEY_H             = 'h33;
localparam [15:0] PS2_KEY_J             = 'h3b;
localparam [15:0] PS2_KEY_K             = 'h42;
localparam [15:0] PS2_KEY_L             = 'h4b;
localparam [15:0] PS2_KEY_SEMICOLON     = 'h4c;
localparam [15:0] PS2_KEY_QUOTE         = 'h52;
localparam [15:0] PS2_KEY_BACKSLASH     = 'h5d;

// zxcvbn
localparam [15:0] PS2_KEY_SHIFT         = 'h12;
localparam [15:0] PS2_KEY_Z             = 'h1a;
localparam [15:0] PS2_KEY_X             = 'h22;
localparam [15:0] PS2_KEY_C             = 'h21;
localparam [15:0] PS2_KEY_V             = 'h2a;
localparam [15:0] PS2_KEY_B             = 'h32;
localparam [15:0] PS2_KEY_N             = 'h31;
localparam [15:0] PS2_KEY_M             = 'h3a;
localparam [15:0] PS2_KEY_COMMA         = 'h41;
localparam [15:0] PS2_KEY_DOT           = 'h49;
localparam [15:0] PS2_KEY_SLASH         = 'h4a;
localparam [15:0] PS2_KEY_SHIFT_RIGHT   = 'h59;

// other non-english layout codes
localparam [15:0] PS2_KEY_LESS_THAN     = 'h61;

// spacebar row
localparam [15:0] PS2_KEY_CONTROL       = 'h14;
localparam [15:0] PS2_KEY_ALT           = 'h11;
localparam [15:0] PS2_KEY_WIN           = 'he01f;
localparam [15:0] PS2_KEY_SPACE         = 'h29;
localparam [15:0] PS2_KEY_ALTGR         = 'he011;
localparam [15:0] PS2_KEY_WIN_RIGHT     = 'he027;
localparam [15:0] PS2_KEY_WIN_MENU      = 'he02f;
localparam [15:0] PS2_KEY_CONTROL_RIGHT = 'he014;

// edit keys
localparam [15:0] PS2_KEY_INS           = 'he070;
localparam [15:0] PS2_KEY_HOME          = 'he06c;
localparam [15:0] PS2_KEY_DEL           = 'he071;
localparam [15:0] PS2_KEY_END           = 'he069;
localparam [15:0] PS2_KEY_PAG_UP        = 'he07d;
localparam [15:0] PS2_KEY_PAG_DOWN      = 'he07a;

// system keys
localparam [15:0] PS2_KEY_PAUSE         = 'h77;
localparam [15:0] PS2_KEY_PRTSCRN       = 'he07c;

// cursor keys
localparam [15:0] PS2_KEY_UP            = 'he075;
localparam [15:0] PS2_KEY_DOWN          = 'he072;
localparam [15:0] PS2_KEY_LEFT          = 'he06b;
localparam [15:0] PS2_KEY_RIGHT         = 'he074;

// numpad
localparam [15:0] PS2_KEY_1_NUMPAD      = 'h69;
localparam [15:0] PS2_KEY_2_NUMPAD      = 'h72;
localparam [15:0] PS2_KEY_3_NUMPAD      = 'h7a;
localparam [15:0] PS2_KEY_4_NUMPAD      = 'h6b;
localparam [15:0] PS2_KEY_5_NUMPAD      = 'h73;
localparam [15:0] PS2_KEY_6_NUMPAD      = 'h74;
localparam [15:0] PS2_KEY_7_NUMPAD      = 'h6c;
localparam [15:0] PS2_KEY_8_NUMPAD      = 'h75;
localparam [15:0] PS2_KEY_9_NUMPAD      = 'h7d;
localparam [15:0] PS2_KEY_0_NUMPAD      = 'h70;
localparam [15:0] PS2_KEY_RETURN_NUMPAD = 'he05a;
localparam [15:0] PS2_KEY_MINUS_NUMPAD  = 'h7b;
localparam [15:0] PS2_KEY_PLUS_NUMPAD   = 'h79;
localparam [15:0] PS2_KEY_MULT_NUMPAD   = 'h7c;
localparam [15:0] PS2_KEY_SLASH_NUMPAD  = 'he04a;
localparam [15:0] PS2_KEY_DOT_NUMPAD    = 'h71;

// PS2 to C16 key mapping
localparam [15:0] KEY_HELP      = PS2_KEY_F4;
localparam [15:0] KEY_F3        = PS2_KEY_F3;
localparam [15:0] KEY_F2        = PS2_KEY_F2;
localparam [15:0] KEY_F1        = PS2_KEY_F1;
localparam [15:0] KEY_AT        = PS2_KEY_OPEN_BRACKET;
localparam [15:0] KEY_POUND     = PS2_KEY_MINUS;
localparam [15:0] KEY_RETURN    = PS2_KEY_RETURN;
localparam [15:0] KEY_INST_DEL  = PS2_KEY_BACKSPACE;
localparam [15:0] KEY_RIGHT     = PS2_KEY_RIGHT;
localparam [15:0] KEY_PLUS      = PS2_KEY_CLOSE_BRACKET;
localparam [15:0] KEY_EQUAL     = PS2_KEY_EQUAL;
localparam [15:0] KEY_ESC       = PS2_KEY_ESC;
localparam [15:0] KEY_SLASH     = PS2_KEY_SLASH;
localparam [15:0] KEY_SEMICOLON = PS2_KEY_SEMICOLON;
localparam [15:0] KEY_ASTERISK  = PS2_KEY_BACKSLASH;
localparam [15:0] KEY_LEFT      = PS2_KEY_LEFT;
localparam [15:0] KEY_UP        = PS2_KEY_UP;
localparam [15:0] KEY_MINUS     = PS2_KEY_F10;
localparam [15:0] KEY_COLON     = PS2_KEY_SEMICOLON;
localparam [15:0] KEY_DOT       = PS2_KEY_DOT;
localparam [15:0] KEY_COMMA     = PS2_KEY_COMMA;
localparam [15:0] KEY_L         = PS2_KEY_L;
localparam [15:0] KEY_P         = PS2_KEY_P;
localparam [15:0] KEY_DOWN      = PS2_KEY_DOWN;
localparam [15:0] KEY_0         = PS2_KEY_0;
localparam [15:0] KEY_O         = PS2_KEY_O;
localparam [15:0] KEY_K         = PS2_KEY_K;
localparam [15:0] KEY_M         = PS2_KEY_M;
localparam [15:0] KEY_N         = PS2_KEY_N;
localparam [15:0] KEY_J         = PS2_KEY_J;
localparam [15:0] KEY_I         = PS2_KEY_I;
localparam [15:0] KEY_9         = PS2_KEY_9;
localparam [15:0] KEY_8         = PS2_KEY_8;
localparam [15:0] KEY_U         = PS2_KEY_U;
localparam [15:0] KEY_H         = PS2_KEY_H;
localparam [15:0] KEY_B         = PS2_KEY_B;
localparam [15:0] KEY_V         = PS2_KEY_V;
localparam [15:0] KEY_G         = PS2_KEY_G;
localparam [15:0] KEY_Y         = PS2_KEY_Y;
localparam [15:0] KEY_7         = PS2_KEY_7;
localparam [15:0] KEY_6         = PS2_KEY_6;
localparam [15:0] KEY_T         = PS2_KEY_T;
localparam [15:0] KEY_F         = PS2_KEY_F;
localparam [15:0] KEY_C         = PS2_KEY_C;
localparam [15:0] KEY_X         = PS2_KEY_X;
localparam [15:0] KEY_D         = PS2_KEY_D;
localparam [15:0] KEY_R         = PS2_KEY_R;
localparam [15:0] KEY_5         = PS2_KEY_5;
localparam [15:0] KEY_4         = PS2_KEY_4;
localparam [15:0] KEY_E         = PS2_KEY_E;
localparam [15:0] KEY_S         = PS2_KEY_S;
localparam [15:0] KEY_Z         = PS2_KEY_Z;
localparam [15:0] KEY_SHIFT     = PS2_KEY_SHIFT;
localparam [15:0] KEY_A         = PS2_KEY_A;
localparam [15:0] KEY_W         = PS2_KEY_W;
localparam [15:0] KEY_3         = PS2_KEY_3;
localparam [15:0] KEY_2         = PS2_KEY_2;
localparam [15:0] KEY_Q         = PS2_KEY_Q;
localparam [15:0] KEY_CBM       = PS2_KEY_WIN;
localparam [15:0] KEY_SPACE     = PS2_KEY_SPACE;
localparam [15:0] KEY_RUN_STOP  = PS2_KEY_TAB;
localparam [15:0] KEY_CTRL      = PS2_KEY_CONTROL;
localparam [15:0] KEY_CLR_HOME  = PS2_KEY_HOME;
localparam [15:0] KEY_1         = PS2_KEY_1;
