package Catalyst::Controller::Validation::DFV;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use version; our $VERSION = qv(0.0.4)->numify;

use base 'Catalyst::Controller';

use Carp;
use Data::FormValidator '4.50';
use Data::FormValidator::Constraints qw(:closures);

sub form_check :Private {
    my ($self, $c, $dfv_profile) = @_;

    my $results = Data::FormValidator->check(
        $c->request->body_parameters,
        $dfv_profile
    );

    # return our findings ...
    $c->stash->{validation} = $results;

    return;
}

sub add_form_invalid :Private {
    my ($self, $c, $invalid_key, $invalid_value) = @_;

    # if we haven't checked hte form yet, we can't add to the results
    if (not defined $c->stash->{validation}) {
        carp('form must be validated first');
        return;
    }

    # the invalids are a keyed list of constraint names
    push
        @{ $c->stash->{validation}{invalid}{$invalid_key} },
        $invalid_value
    ;

    return;
}

sub validation_errors_to_html :Private {
    my ($self, $c) = @_;
}

# factored out of a block of code I regularly paste into Controller/Root.pm
sub refill_form :Private {
    my ($self, $c) = @_;

    if (not $c->can('fillform')) {
        # put a warning in the logs
        $c->log->warn(
            q{The context object doesn't have a fillform() method. Add 'FillInForm' to your plug-in list.}
        );

        return; # no point in continuing
    }

    # use Catalyst::Plugin::FillInForm to refill form data
    # in order of priority we have:
    #  - stash->{formdata}
    #  - ->parameters()
    #  - <input value="...">
    $c->fillform(
        {
            # combine two hashrefs so we only make one method call
            %{ $c->request->parameters || {} },
            %{ $c->stash->{formdata}   || {} },
        }
    );

    return;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::Validation::DFV - check form data

=head1 SUMMARY

Form-validation using a Catalyst controller and Data::FormValidator

=head1 SYNOPSIS

=head2 Form Validation

    use base 'Catalyst::Controller::Validation::DFV';
    use Data::FormValidator::Constraints qw(:closures);

    # define a DFV profile
    my $dfv_profile = {
        required => [qw<
            email_address
            phone_home
            phone_mobile
        >],

        constraint_methods => {
            email_address   => email(),
            phone_home      => american_phone(),
            phone_mobile    => american_phone(),
        },
    };

    # check the form for errors
    $c->forward('form_check', [$dfv_profile]);

    # perform custom/complex checking and
    # add to form validation failures
    if (not is_complex_test_ok()) {
        $c->forward(
            'add_form_invalid',
            [ $error_key, $error_constraint_name ]
        );
    }

=head2 Form Refilling

    package MyApp::Controller::Root;

    # ...

    use base 'Catalyst::Controller::Validation::DFV';

    # ...

    sub render : ActionClass('RenderView') {
        # ...
    }

    sub end : Private {
        my ($self, $c) = @_;

        # render the page
        $c->forward('render');

        # fill in any forms
        $c->forward('refill_form');
    }

=head1 EXAMPLES

There are L<Template::Toolkit> file examples in the examples/ directory of
this distribution.

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
