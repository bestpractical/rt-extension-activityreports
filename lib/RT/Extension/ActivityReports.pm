package RT::Extension::ActivityReports;

use Exporter qw( import );
@EXPORT_OK = qw( RelevantTxns );

our $VERSION = '1.02';

=head2 RelevantTxns( $ticket, \%args )

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

    my $txns = $ticket->Transactions;
    $txns->Limit(FIELD => 'Created', OPERATOR => '>=', VALUE => $args{start});
    $txns->Limit(FIELD => 'Created', OPERATOR => '<=', VALUE => $args{end});
    if( $args{timed} ) {
	# Limit to transactions with positive time taken.
        $txns->Limit(FIELD => 'TimeTaken', OPERATOR => '>=', VALUE => 1); 
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
