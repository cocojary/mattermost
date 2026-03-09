// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React from 'react';
import styled from 'styled-components';

import techzenLogo from 'images/brand/tz-logo.png';

const ProductBrandingFreeEditionContainer = styled.span`
    display: flex;
    align-items: center;
    padding-left: 8px;
`;

const ProductBrandingFreeEdition = (): JSX.Element => {
    return (
        <ProductBrandingFreeEditionContainer tabIndex={-1}>
            <img
                src={techzenLogo}
                alt="Techzen Academy"
                height={24}
                style={{ objectFit: 'contain' }}
            />
        </ProductBrandingFreeEditionContainer>
    );
};

export default ProductBrandingFreeEdition;
