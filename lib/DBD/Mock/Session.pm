package DBD::Mock::Session;

use strict;
use warnings;

my $INSTANCE_COUNT = 1;

sub new {
    my $class = shift;
    my $name = ref( $_[0] ) ? "Session $INSTANCE_COUNT" : shift;

    $class->_verify_states( $name, @_ );

    $INSTANCE_COUNT++;
    bless {
        name        => $name,
        states      => \@_,
        state_index => 0
    }, $class;
}

sub name       { (shift)->{name} }
sub reset      { (shift)->{state_index} = 0 }
sub num_states { scalar( @{ (shift)->{states} } ) }

sub _verify_states {
    my ( $class, $name, @states ) = @_;

    my $index = 0;

    die "You must specify at least one session state"
      if not scalar(@states);

    foreach (@states) {
        die "You must specify session states as HASH refs"
          if ref($_) ne 'HASH';

        die "Bad state '$index' in DBD::Mock::Session ($name)"
          if not exists $_->{statement}
              or not exists $_->{results};

        die
"Bad 'statement' value '$_->{statement}' in DBD::Mock::Session ($name)"
          if ref( $_->{statement} ) ne ''
              and ref( $_->{statement} ) ne 'CODE'
              and ref( $_->{statement} ) ne 'Regexp';

    }

}

sub current_state {
    my $self = shift;
    my $idx  = $self->{state_index};
    return $self->{states}[$idx];
}

sub has_states_left {
    my $self = shift;
    return $self->{state_index} < scalar( @{ $self->{states} } );
}

sub _remaining_states {
    my $self        = shift;
    my $start_index = $self->{state_index};
    my $end_index   = $self->num_states - 1;
    @{ $self->{states} }[ $start_index .. $end_index ];
}

sub _find_state_for {
    my ( $self, $statement ) = @_;

    foreach ( $self->_remaining_states ) {
        my $stmt = $_->{statement};
        my $ref  = ref($stmt);

        return $_ if ( $ref eq 'Regexp' and $statement =~ /$stmt/ );
        return $_ if ( $ref eq 'CODE' and $stmt->( $statement, $_ ) );
        return $_ if ( not $ref and $stmt eq $statement );
    }

    die "Bad 'statement' value '$statement' in session ($self->{name})";
}

sub verify_statement {
    my ( $self, $statement ) = @_;

    die "Session states exhausted, only '"
      . scalar( @{ $self->{states} } )
      . "' in DBD::Mock::Session ($self->{name})"
      unless $self->has_states_left;

    my $stmt = $self->current_state->{statement};
    my $ref  = ref($stmt);

    if ( $ref eq 'Regexp' and $statement !~ /$stmt/ ) {
        die
"Statement does not match current state (with Regexp) in DBD::Mock::Session ($self->{name})\n"
          . "      got: $statement\n"
          . " expected: $stmt";
    }

    if ( $ref eq 'CODE' and not $stmt->( $statement, $_ ) ) {
        die
"Statement does not match current state (with CODE ref) in DBD::Mock::Session ($self->{name})";

    }

    if ( not $ref and $stmt ne $statement ) {
        die
"Statement does not match current state in DBD::Mock::Session ($self->{name})\n"
          . "      got: $statement\n"
          . " expected: $stmt";
    }

}

sub results_for {
    my ( $self, $statment ) = @_;
    $self->_find_state_for($statment)->{results};
}

sub verify_bound_params {
    my ( $self, $params ) = @_;

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
