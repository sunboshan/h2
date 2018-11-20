-module(h2).
-export([start/1,init/1]).

start(Host) ->
    spawn(h2,init,[Host]).

init(Host) ->
    {ok,Socket} = ssl:connect(Host,443,[
        binary,
        {alpn_advertised_protocols,[<<"h2">>]}
        ]),
    Magic = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n",
    Settings = <<0,0,0,4,0,0,0,0,0>>,
    ssl:send(Socket,[Magic,Settings]),
    loop(Socket).

loop(Socket) ->
    receive
        {ssl,Socket,Data} ->
            parse(Data),
            loop(Socket);

        {send,Data} ->
            ssl:send(Socket,Data),
            loop(Socket)
    end.

parse(<<_:24,4,0,_/binary>>) -> io:format("Got SETTINGS~n");
parse(<<_:24,4,1,_/binary>>) -> io:format("Got SETTINGS_ACK~n");
parse(<<_:24,8,_/binary>>) -> io:format("Got WINDOWN_UPDATE~n");
parse(<<Sz:24,1,_:5/binary,_:Sz/binary,Rest/binary>>) -> io:format("Got HEADERS~n"),parse(Rest);
parse(<<_:24,0,_:5/binary,Rest/binary>>) -> io:format("~s~n",[Rest]);
parse(<<_:24,_,_/binary>> = Data) -> io:format("Got other frame ~p~n",[Data]).
