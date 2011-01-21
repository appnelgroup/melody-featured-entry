package MT::FeaturedEntry::Sticky;
use strict;
use warnings;

#--- transformer handlers

sub add_sticky_checkbox {
    my ($eh, $app, $param, $tmpl) = @_;
    return unless $tmpl->isa('MT::Template');
    my $q           = $app->param;
    my $blog_id     = $q->param('blog_id');
    my $entry_class = $app->model('entry');
    my $entry_id    = $app->param('id');
    my $entry;
    my $checked = '';
    if ($entry_id) {
        $entry = $entry_class->load($entry_id, {cached_ok => 1});
        $checked = "checked=\"checked\"" if $entry->is_featured;
    }
    my $innerHTML;
    $innerHTML =
"<input type='checkbox' id='featured_entry' name='featured_entry' $checked value='1' />";

    my $host_node = $tmpl->getElementById('status')
      or return $app->error('cannot get the status block');
    my $block_node =
      $tmpl->createElement(
                           'app:setting',
                           {
                            id    => 'featured_entry',
                            label => 'Feature Entry',
                           }
      ) or return $app->error('cannot create the element');
    $block_node->innerHTML($innerHTML);
    $tmpl->insertBefore($block_node, $host_node)
      or return $app->error('failed to insertBefore.');
}

sub save_featured_status {
    my ($cb, $app, $obj, $orig) = @_;
    my $is_featured = $app->param('featured_entry') || 0;
    $obj->is_featured($is_featured);
    $obj->save;
}

#--- template tag handlers

sub blog_sticky_entry {
    my ($ctx, $args, $cond) = @_;
    $args->{lastn} = 1;
    return blog_sticky_entries($ctx,$args, $cond);
}

sub blog_stick_entries {
    my ($ctx, $args, $cond) = @_;
    my $blog_id = $ctx->stash('blog_id');
    unless ($blog_id) {
        my $blog = $ctx->stash('blog');
        $blog_id = $blog->id;
    }
    my $limit = $args->{lastn} || 1;
    require MT::Entry;
    my $entry = MT::Entry->load(
                                {is_featured => 1, blog_id => $blog_id},
                                {
                                 limit     => $limit,
                                 'sort'    => 'created_on',
                                 status    => MT::Entry::RELEASE(),
                                 direction => 'descend'
                                }
    );
    return '' unless $entry;
    $ctx->stash('entry', $entry);
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $out     = $builder->build($ctx, $tokens, $cond);
    return $out;
}

sub if_blog_has_sticky {
    my ($ctx, $args, $cond) = @_;
    my $blog_id = $ctx->stash('blog_id');
    unless ($blog_id) {
        my $blog = $ctx->stash('blog');
        $blog_id = $blog->id;
    }
    require MT::Entry;
    my $sticky_entries =
      MT::Entry->count({is_featured => 1, blog_id => $blog_id});
    if ($sticky_entries > 0) {
        return 1;
    } else {
        return 0;
    }
}

sub if_entry_is_sticky {
    my ($ctx, $args, $cond) = @_;
    my $entry = $ctx->stash('entry');
    if (!$entry) {
        return 0;
    }
    my $entry_is_sticky = $entry->is_featured || 0;
    return $entry_is_sticky;
}

1;

__END__

