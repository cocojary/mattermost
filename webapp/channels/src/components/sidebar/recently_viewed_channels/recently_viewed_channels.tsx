// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React from 'react';
import { FormattedMessage } from 'react-intl';

import type { Channel } from '@mattermost/types/channels';

type Props = {
    recentChannels: Channel[];
    currentChannelId: string;
    onChannelClick: (channelId: string) => void;
};

type State = {
    isCollapsed: boolean;
};

export default class RecentlyViewedChannels extends React.PureComponent<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = {
            isCollapsed: false,
        };
    }

    toggleCollapse = () => {
        this.setState((prevState) => ({ isCollapsed: !prevState.isCollapsed }));
    };

    handleChannelClick = (channelId: string) => (e: React.MouseEvent) => {
        e.preventDefault();
        this.props.onChannelClick(channelId);
    };

    render() {
        const { recentChannels, currentChannelId } = this.props;

        if (!recentChannels || recentChannels.length === 0) {
            return null;
        }

        // Filter out the current channel from display
        const filteredChannels = recentChannels.filter((ch) => ch.id !== currentChannelId);

        if (filteredChannels.length === 0) {
            return null;
        }

        return (
            <div className='recently-viewed-channels'>
                <button
                    className='recently-viewed-channels__header'
                    onClick={this.toggleCollapse}
                    aria-expanded={!this.state.isCollapsed}
                >
                    <i className={`icon icon-chevron-${this.state.isCollapsed ? 'right' : 'down'}`} />
                    <FormattedMessage
                        id='sidebar.recentlyViewed'
                        defaultMessage='Recently Viewed'
                    />
                    <span className='recently-viewed-channels__count'>
                        {filteredChannels.length}
                    </span>
                </button>
                {!this.state.isCollapsed && (
                    <ul className='recently-viewed-channels__list'>
                        {filteredChannels.map((channel) => (
                            <li
                                key={channel.id}
                                className='recently-viewed-channels__item'
                            >
                                <button
                                    className='recently-viewed-channels__link'
                                    onClick={this.handleChannelClick(channel.id)}
                                    title={channel.display_name}
                                >
                                    <i className={`icon ${channel.type === 'D' ? 'icon-account-outline' : channel.type === 'G' ? 'icon-account-multiple-outline' : channel.type === 'P' ? 'icon-lock-outline' : 'icon-globe'}`} />
                                    <span className='recently-viewed-channels__name'>
                                        {channel.display_name || channel.name}
                                    </span>
                                </button>
                            </li>
                        ))}
                    </ul>
                )}
            </div>
        );
    }
}
