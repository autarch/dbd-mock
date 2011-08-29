package DBD::Mock::Session;

use strict;
use warnings;

my $INSTANCE_COUNT = 1;

sub new {
    my $class = shift;
    (@_) || die "You must specify at least one session state";
    my $session_name;
    if ( ref( $_[0] ) ) {
        $session_name = 'Session ' . $INSTANCE_COUNT;
    }
    else {
        $session_name = shift;
    }
    my @session_states = @_;
    (@session_states)
      || die "You must specify at least one session state";
    ( ref($_) eq 'HASH' )
      || die "You must specify session states as HASH refs"
      foreach @session_states;
    $INSTANCE_COUNT++;
    return bless {
        name        => $session_name,
        states      => \@session_states,
        state_index => 0
    } => $class;
}

sub name       { (shift)->{name} }
sub reset      { (shift)->{state_index} = 0 }
sub num_states { scalar( @{ (shift)->{states} } ) }

sub current_state {
    my $self = shift;
    my $idx  = $self->{state_index};
    return $self->{states}[$idx];
}

sub has_states_left {
    my $self = shift;
    return $self->{state_index} < scalar( @{ $self->{states} } );
}

sub verify_statement {
    my ( $self, $dbh, $statement ) = @_;

    ( $self->has_states_left )
      || die "Session states exhausted, only '"
      . scalar( @{ $self->{states} } )
      . "' in DBD::Mock::Session ("
      . $self->{name} . ")";

    my $current_state = $self->current_state;

    # make sure our state is good
    ( exists ${$current_state}{statement} && exists ${$current_state}{results} )
      || die "Bad state '"
      . $self->{state_index}
      . "' in DBD::Mock::Session ("
      . $self->{name} . ")";

    # try the SQL
    my $SQL = $current_state->{statement};
    unless ( ref($SQL) ) {
        ( $SQL eq $statement )
          || die
          "Statement does not match current state in DBD::Mock::Session ("
          . $self->{name} . ")\n"
          . "      got: $statement\n"
          . " expected: $SQL";
    }
    elsif ( ref($SQL) eq 'Regexp' ) {
        ( $statement =~ /$SQL/ )
          || die
"Statement does not match current state (with Regexp) in DBD::Mock::Session ("
          . $self->{name} . ")\n"
          . "      got: $statement\n"
          . " expected: $SQL";
    }
    elsif ( ref($SQL) eq 'CODE' ) {
        ( $SQL->( $statement, $current_state ) )
          || die
"Statement does not match current state (with CODE ref) in DBD::Mock::Session ("
          . $self->{name} . ")";
    }
    else {
        die
"Bad 'statement' value '$SQL' in current state in DBD::Mock::Session ("
          . $self->{name} . ")";
    }

    # copy the result sets so that
    # we can re-use the session
    $dbh->STORE( 'mock_add_resultset' => [ @{ $current_state->{results} } ] );
}

sub verify_bound_params {
    my ( $self, $dbh, $params ) = @_;

    my $current_state = $self->current_state;
    if ( exists ${$current_state}{bound_params} ) {
        my $expected = $current_state->{bound_params};
        ( scalar( @{$expected} ) == scalar( @{$params} ) )
          || die
"Not the same number of bound params in current state in DBD::Mock::Session ("
          . $self->{name} . ")\n"
          . "      got: "
          . scalar( @{$params} ) . "\n"
          . " expected: "
          . scalar( @{$expected} );
        for ( my $i = 0 ; $i < scalar( @{$params} ) ; $i++ ) {
            no warnings;
            if ( ref( $expected->[$i] ) eq 'Regexp' ) {
                ( $params->[$i] =~ /$expected->[$i]/ )
                  || die
"Bound param $i do not match (using regexp) in current state in DBD::Mock::Session ("
                  . $self->{name} . ")\n"
                  . "      got: "
                  . $params->[$i] . "\n"
                  . " expected: "
                  . $expected->[$i];
            }
            else {
                ( $params->[$i] eq $expected->[$i] )
                  || die
"Bound param $i do not match in current state in DBD::Mock::Session ("
                  . $self->{name} . ")\n"
                  . "      got: "
                  . $params->[$i] . "\n"
                  . " expected: "
                  . $expected->[$i];
            }
        }
    }

    # and make sure we go to
    # the next statement
    $self->{state_index}++;
}

1;
