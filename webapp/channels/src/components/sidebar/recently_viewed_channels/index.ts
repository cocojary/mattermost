// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import { connect } from 'react-redux';

import { getAllChannels, getCurrentChannelId } from 'mattermost-redux/selectors/entities/channels';

import { switchToChannelById } from 'actions/views/channel';
import { getRecentlyViewedChannelIds } from 'selectors/views/channel_sidebar';

import type { GlobalState } from 'types/store';

import RecentlyViewedChannels from './recently_viewed_channels';

function mapStateToProps(state: GlobalState) {
    const recentChannelIds = getRecentlyViewedChannelIds(state);
    const allChannels = getAllChannels(state);
    const currentChannelId = getCurrentChannelId(state);

    // Resolve channel IDs to full Channel objects, filtering out deleted/missing channels
    const recentChannels = recentChannelIds
        .map((id) => allChannels[id])
        .filter((ch) => ch && ch.delete_at === 0);

    return {
        recentChannels,
        currentChannelId,
    };
}

function mapDispatchToProps(dispatch: any) {
    return {
        onChannelClick: (channelId: string) => dispatch(switchToChannelById(channelId)),
    };
}

export default connect(mapStateToProps, mapDispatchToProps)(RecentlyViewedChannels);
