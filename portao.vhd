library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity portao is
  generic (
    T_MAX : natural := 5   -- tempo máximo em ciclos no estado ABERTO
  );
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;   -- reset assíncrono, ativo em '0'

    bot        : in  std_logic;   -- botão principal (abre/fecha/pausa)
    end_open   : in  std_logic;   -- fim de curso portão totalmente aberto
    end_close  : in  std_logic;   -- fim de curso portão totalmente fechado
    obst       : in  std_logic;   -- sensor de obstáculo
    stop       : in  std_logic;   -- parada/ emergência (força EMERGENCIA)

    motor_open  : out std_logic;  -- liga motor no sentido abrir
    motor_close : out std_logic;  -- liga motor no sentido fechar

    state_debug : out std_logic_vector(2 downto 0)  -- LEDs de debug/estado
  );
end entity portao;

architecture rtl of portao is

  ---------------------------------------------------------------------------
  -- Definição de estados (tipo enumerado, mesmos nomes da HLSM)
  ---------------------------------------------------------------------------
  type state_type is (
    FECHADO,
    ABRINDO,
    ABERTO,
    FECHANDO,
    PARE,
    EMERGENCIA
  );

  signal state_reg, state_next : state_type;

  ---------------------------------------------------------------------------
  -- Temporizador: timer_count, t_max, t_expired
  ---------------------------------------------------------------------------
  signal timer_count    : unsigned(15 downto 0) := (others => '0');
  signal timer_count_en : std_logic := '0';
  signal t_expired      : std_logic;

  ---------------------------------------------------------------------------
  -- Sincronização e detecção de borda do bot
  ---------------------------------------------------------------------------
  signal bot_sync_0, bot_sync_1 : std_logic := '0';
  signal bot_rise               : std_logic;

begin

  ---------------------------------------------------------------------------
  -- 1) SINCRONIZAÇÃO DO BOTÃO (flip-flops)
  ---------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      bot_sync_0 <= '0';
      bot_sync_1 <= '0';
    elsif rising_edge(clk) then
      bot_sync_0 <= bot;
      bot_sync_1 <= bot_sync_0;
    end if;
  end process;

  -- detecção de borda de subida de bot
  bot_rise <= '1' when (bot_sync_0 = '1' and bot_sync_1 = '0') else '0';

  ---------------------------------------------------------------------------
  -- 2) REGISTRADOR DE ESTADO (FSM)
  ---------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      state_reg <= FECHADO;
    elsif rising_edge(clk) then
      state_reg <= state_next;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- 3) CONTADOR DE TEMPO (timer_count)
  ---------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      timer_count <= (others => '0');
    elsif rising_edge(clk) then
      if timer_count_en = '1' then
        if timer_count = to_unsigned(T_MAX - 1, timer_count'length) then
          timer_count <= timer_count;  -- trava no máximo
        else
          timer_count <= timer_count + 1;
        end if;
      else
        timer_count <= (others => '0');
      end if;
    end if;
  end process;

  t_expired <= '1'
    when timer_count = to_unsigned(T_MAX - 1, timer_count'length)
    else '0';

  ---------------------------------------------------------------------------
  -- 4) Habilita o temporizador APENAS em ABERTO
  ---------------------------------------------------------------------------
  timer_count_en <= '1' when state_reg = ABERTO else '0';

  ---------------------------------------------------------------------------
  -- 5) LÓGICA COMBINACIONAL DE PRÓXIMO ESTADO (estilo HLSM)
  ---------------------------------------------------------------------------
  state_next <=
    -- prioridade: stop domina tudo
    EMERGENCIA when stop = '1' else

    -- FECHADO
    ABRINDO    when (state_reg = FECHADO and bot_rise = '1') else

    -- ABRINDO
    ABERTO     when (state_reg = ABRINDO and end_open = '1') else
    PARE       when (state_reg = ABRINDO and end_open = '0' and bot_rise = '1') else

    -- ABERTO  (fecha se apertar bot OU se t_expired = 1)
    FECHANDO   when (state_reg = ABERTO and
                     (bot_rise = '1' or t_expired = '1')) else

    -- FECHANDO
    FECHADO    when (state_reg = FECHANDO and end_close = '1') else
    ABRINDO    when (state_reg = FECHANDO and end_close = '0' and obst = '1') else
    PARE       when (state_reg = FECHANDO and end_close = '0' and obst = '0' and bot_rise = '1') else

    -- PARE (volta fechando quando apertar bot)
    FECHANDO   when (state_reg = PARE and bot_rise = '1') else

    -- EMERGENCIA: permanece até reset
    EMERGENCIA when (state_reg = EMERGENCIA) else

    -- default: mantém estado
    state_reg;

  ---------------------------------------------------------------------------
  -- 6) LÓGICA DE SAÍDA (Moore)
  ---------------------------------------------------------------------------

  -- motor: sentido de abrir / fechar
  motor_open  <= '1' when state_reg = ABRINDO  else '0';
  motor_close <= '1' when state_reg = FECHANDO else '0';

  -- state_debug: codificação dos estados (pra LEDs)
  with state_reg select
    state_debug <=
      "000" when FECHADO,
      "001" when ABRINDO,
      "010" when ABERTO,
      "011" when FECHANDO,
      "100" when PARE,
      "101" when EMERGENCIA,
      "000" when others;

end architecture rtl;
