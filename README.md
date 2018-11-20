# h2

A simple http2 client that demonstrate how to make http2 GET request in 33 lines of code.

## Usage

```
➜ make run
Erlang/OTP 21 [erts-10.1.1] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe] [dtrace]

Eshell V10.1.1  (abort with ^G)
1> P=h2:start("http2.golang.org").
<0.99.0>
Got SETTINGS
Got WINDOWN_UPDATE
Got SETTINGS_ACK

2> P ! {send,<<0,0,21,1,5,0,0,0,1,130,135,132,1,16,104,116,116,112,50,46,103,111,108,97,110,103,46,111,114,103>>}.
{send,<<0,0,21,1,5,0,0,0,1,130,135,132,1,16,104,116,116,
        112,50,46,103,111,108,97,110,103,46,...>>}
Got HEADERS
<html>
<body>
<h1>Go + HTTP/2</h1>

<p>Welcome to <a href="https://golang.org/">the Go language</a>'s <a
href="https://http2.github.io/">HTTP/2</a> demo & interop server.</p>

<p>Congratulations, <b>you're using HTTP/2 right now</b>.</p>

<p>This server exists for others in the HTTP/2 community to test their HTTP/2 client implementations and point out flaws in our server.</p>

...
</body></html>
```

## Explaination of data sent

In above example, a data was sent to the process and then we got our http2 response back. What is that data?

```
    <<0,0,21,1,5,0,0,0,1,130,135,132,1,16,104,116,116,112,50,46,103,111,108,97,110,103,46,111,114,103>>

    % let's broken down the data

    0,0,21,        % length(21)
    1,5,           % type(HEADERS), flags(END_HEADERS & END_STREAM)
    0,0,0,1,       % stream id(1)
    130,135,132,   % header block fragment
    1,16,104,116,116,112,50,46,103,111,108,97,110,103,46,111,114,103

    % this is HTTP/2 HEADERS Frame

    +-----------------------------------------------+
    |                 Length (24)                   |
    +---------------+---------------+---------------+
    |   Type (8)    |   Flags (8)   |
    +-+-------------+---------------+-------------------------------+
    |R|                 Stream Identifier (31)                      |
    +=+=============================================================+
    |                   Header Block Fragment (*)                 ...
    +---------------------------------------------------------------+

    % for the header block fragment, we are sending headers like this

    :method: GET
    :scheme: https
    :path: /
    :authority: http2.golang.org

    +-------+-----------------------------+------------------+
    | Index | Header Name                 | Header Value     |
    +-------+-----------------------------+------------------+
    | 1     | :authority                  |                  |  http2.golang.org
    | 2     | :method                     | GET              |
    | 4     | :path                       | /                |
    | 7     | :scheme                     | https            |
    +-------+-----------------------------+------------------+

    % for the static table, we have 3 header pairs indexed in the table,
    % which encoded using the following format

      0   1   2   3   4   5   6   7
    +---+---+---+---+---+---+---+---+
    | 1 |        Index (7+)         |
    +---+---------------------------+

    +---+---+---+---+---+---+---+---+
    | 1 | 0   0   0   0   0   1   0 |    <<130>>
    +---+---------------------------+
    +---+---+---+---+---+---+---+---+
    | 1 | 0   0   0   0   1   1   1 |    <<135>>
    +---+---------------------------+
    +---+---+---+---+---+---+---+---+
    | 1 | 0   0   0   0   1   0   0 |    <<132>>
    +---+---------------------------+

    % for the :authority, which key is indexed but we have to provide the value,
    % it's encoded as following

      0   1   2   3   4   5   6   7
    +---+---+---+---+---+---+---+---+
    | 0 | 0 | 0 | 0 |  Index (4+)   |
    +---+---+-----------------------+
    | H |     Value Length (7+)     |
    +---+---------------------------+
    | Value String (Length octets)  |
    +-------------------------------+

    +-------+-----------------------------+------------------+
    | Index | Header Name                 | Header Value     |
    +-------+-----------------------------+------------------+
    | 1     | :authority                  |                  |  http2.golang.org
    +-------+-----------------------------+------------------+

    +---+---+---+---+---+---+---+---+
    | 0 | 0 | 0 | 0 | 0   0   0   1 |    1
    +---+---+-----------------------+
    | 0 | 0   0   1   0   0   0   0 |    16
    +---+---------------------------+
    | 0   1   1   0   1   0   0   0 |    104(h)
    +-------------------------------+
    | 0   1   1   1   0   1   0   0 |    116(t)
    +-------------------------------+
    | 0   1   1   1   0   1   0   0 |    116(t)
    +-------------------------------+
    | 0   1   1   1   0   0   0   0 |    112(p)
    +-------------------------------+
    | 0   0   1   1   0   0   1   0 |     50(2)
    +-------------------------------+
    ...

    <<1,16,104,116,116,112,50,46,103,111,108,97,110,103,46,111,114,103>>
```
