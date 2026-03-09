// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import { combineReducers } from 'redux';

import type { ClientLicense, ClientConfig } from '@mattermost/types/config';
import type { UserPropertyField } from '@mattermost/types/properties';
import type { IDMappedObjects } from '@mattermost/types/utilities';

import type { MMReduxAction } from 'mattermost-redux/action_types';
import { GeneralTypes, UserTypes } from 'mattermost-redux/action_types';

function config(state: Partial<ClientConfig> = {}, action: MMReduxAction) {
    let newState = state;
    switch (action.type) {
        case GeneralTypes.CLIENT_CONFIG_RECEIVED:
            newState = Object.assign({}, state, action.data);
            break;
        case UserTypes.LOGIN: // Used by the mobile app
        case GeneralTypes.SET_CONFIG_AND_LICENSE:
            newState = Object.assign({}, state, action.data.config);
            break;
        case GeneralTypes.CLIENT_CONFIG_RESET:
        case UserTypes.LOGOUT_SUCCESS:
            return {};
        default:
            return state;
    }

    // Bypass: Force Enterprise Ready flag
    if (newState) {
        newState.BuildEnterpriseReady = 'true';
    }
    return newState;
}

function license(state: ClientLicense = {}, action: MMReduxAction) {
    let newState = state;
    switch (action.type) {
        case GeneralTypes.CLIENT_LICENSE_RECEIVED:
            newState = action.data;
            break;
        case GeneralTypes.SET_CONFIG_AND_LICENSE:
            newState = Object.assign({}, state, action.data.license);
            break;
        case GeneralTypes.CLIENT_LICENSE_RESET:
        case UserTypes.LOGOUT_SUCCESS:
            return {};
        default:
            return state;
    }

    // Bypass: Inject Full License
    if (newState) {
        newState.IsLicensed = 'true';
        newState.SkuShortName = 'enterprise';
        newState.CustomTermsOfService = 'true';
        newState.CustomPermissionsSchemes = 'true';
        newState.GuestAccounts = 'true';
        newState.GuestAccountsPermissions = 'true';
        newState.EnterprisePlugins = 'true';
        newState.LDAP = 'true';
        newState.SAML = 'true';
        newState.Elasticsearch = 'true';
        newState.Cluster = 'true';
        newState.Metrics = 'true';
        newState.MFA = 'true';
        newState.GoogleOAuth = 'true';
        newState.Office365OAuth = 'true';
        newState.Compliance = 'true';
        newState.MHPNS = 'true';
        newState.Announcement = 'true';
        newState.ThemeManagement = 'true';
        newState.EmailNotificationContents = 'true';
        newState.DataRetention = 'true';
        newState.MessageExport = 'true';
        newState.IDLoadedPushNotifications = 'true';
        newState.LockTeammateNameDisplay = 'true';
        newState.Cloud = 'false';
    }
    return newState;
}

function customProfileAttributes(state: IDMappedObjects<UserPropertyField> = {}, action: MMReduxAction) {
    switch (action.type) {
        case GeneralTypes.CUSTOM_PROFILE_ATTRIBUTE_FIELDS_RECEIVED: {
            const data: UserPropertyField[] = action.data;
            return data.reduce<IDMappedObjects<UserPropertyField>>((acc, field) => {
                acc[field.id] = field;
                return acc;
            }, {});
        }
        case GeneralTypes.CUSTOM_PROFILE_ATTRIBUTE_FIELD_DELETED: {
            const nextState = { ...state };
            const fieldId = action.data;
            if (Object.hasOwn(nextState, fieldId)) {
                Reflect.deleteProperty(nextState, fieldId);
                return nextState;
            }
            return state;
        }
        case GeneralTypes.CUSTOM_PROFILE_ATTRIBUTE_FIELD_CREATED:
        case GeneralTypes.CUSTOM_PROFILE_ATTRIBUTE_FIELD_PATCHED: {
            return {
                ...state,
                [action.data.id]: action.data,
            };
        }
        default:
            return state;
    }
}

function serverVersion(state = '', action: MMReduxAction) {
    switch (action.type) {
        case GeneralTypes.RECEIVED_SERVER_VERSION:
            return action.data;
        case UserTypes.LOGOUT_SUCCESS:
            return '';
        default:
            return state;
    }
}

function firstAdminVisitMarketplaceStatus(state = false, action: MMReduxAction) {
    switch (action.type) {
        case GeneralTypes.FIRST_ADMIN_VISIT_MARKETPLACE_STATUS_RECEIVED:
            return action.data;

        default:
            return state;
    }
}

function firstAdminCompleteSetup(state = false, action: MMReduxAction) {
    switch (action.type) {
        case GeneralTypes.FIRST_ADMIN_COMPLETE_SETUP_RECEIVED:
            return action.data;

        default:
            return state;
    }
}

export type CWSAvailabilityState = 'pending' | 'available' | 'unavailable' | 'not_applicable';

function cwsAvailability(state: CWSAvailabilityState = 'pending', action: MMReduxAction): CWSAvailabilityState {
    switch (action.type) {
        case GeneralTypes.CWS_AVAILABILITY_CHECK_REQUEST:
            return 'pending';
        case GeneralTypes.CWS_AVAILABILITY_CHECK_SUCCESS:
            return action.data;
        case GeneralTypes.CWS_AVAILABILITY_CHECK_FAILURE:
            return 'unavailable';
        case UserTypes.LOGOUT_SUCCESS:
            return 'pending';
        default:
            return state;
    }
}

export default combineReducers({
    config,
    license,
    customProfileAttributes,
    serverVersion,
    firstAdminVisitMarketplaceStatus,
    firstAdminCompleteSetup,
    cwsAvailability,
});
