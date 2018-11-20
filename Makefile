build:
	@erlc -o ebin src/*.erl

run:
	@ERL_LIBS=. erl -s ssl
