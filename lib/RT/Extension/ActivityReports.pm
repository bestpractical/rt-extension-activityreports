package RT::Extension::ActivityReports;
use RT::Date;

use Exporter qw( import );
@EXPORT_OK = qw( RelevantTxns );

our $VERSION = '1.02';

=head2 RelevantTxns( $ticket, \%args )

$ticket can either be a single RT::Ticket or an RT::Tickets object.

Helper routine for the various activity reports, to get the list of
relevant transactions on each relevant ticket.  Not yet used for
Resolution* or TimeWorked reports.  Args include:

    start
    end
    actor
    timed

=cut

sub RelevantTxns {
    my( $ticket, %args ) = @_;

    my $txns = new RT::Transactions($ticket->CurrentUser);
    if ( $ticket->isa('RT::Tickets') ) {
        while (my $t = $ticket->Next) {
            $txns->LimitToTicket($t->id);
        }
    } else {
        $txns = $ticket->Transactions;
    }

    my $date = new RT::Date( $ticket->CurrentUser );

    $date->Set( Format => 'unknown', Value => $args{start} );
    my $start = $date->AsString( Format => 'sql' );

    $date->Set( Format => 'unknown', Value => $args{end} );
    $date->AddSeconds(86399) if $date->AsString =~ /\b00:00:00\b/;
    my $end = $date->AsString( Format => 'sql' );


    $txns->Limit(FIELD => 'Created', OPERATOR => '>=', VALUE => $start, ENTRYAGGREGATOR => 'AND');
    $txns->Limit(FIELD => 'Created', OPERATOR => '<=', VALUE => $end, ENTRYAGGREGATOR => 'AND');
    if( $args{timed} ) {
	# Limit to transactions with positive time taken.
        $txns->Limit(FIELD => 'TimeTaken', OPERATOR => '>=', VALUE => 1, ENTRYAGGREGATOR => 'AND'); 
    } else {
	# Include status changes and ticket creations.
	$txns->Limit(FIELD => 'Type', VALUE => 'Status', ENTRYAGGREGATOR => 'OR');
	$txns->Limit(FIELD => 'Type', VALUE => 'Create', ENTRYAGGREGATOR => 'OR');
    }
    # Comment/correspond type transactions are always relevant.
    $txns->Limit(FIELD => 'Type', VALUE => 'Comment', ENTRYAGGREGATOR => 'OR');
    $txns->Limit(FIELD => 'Type', VALUE => 'Correspond');

    return $txns;
}

1;
