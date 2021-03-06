/*==============================================================================┐
|               _    _      _                            _                      |  
|              | |  | |    | |                          | |                     |██
|              | |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___                |██
|              | |/\| |/ _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \               |██
|              \  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) |              |██
|               \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/               |██
|                                                                               |██
|                                                                               |██
|          _    _            _____            _ _____                _          |██
|         | |  | |          /  ___|          | /  __ \              | |         |██
|         | |  | | __ ___  _\ `--.  ___  __ _| | /  \/ ___  _ __ ___| |         |██
|         | |/\| |/ _` \ \/ /`--. \/ _ \/ _` | | |    / _ \| '__/ _ \ |         |██
|         \  /\  / (_| |>  </\__/ /  __/ (_| | | \__/\ (_) | | |  __/_|         |██
|          \/  \/ \__,_/_/\_\____/ \___|\__,_|_|\____/\___/|_|  \___(_)         |██
|                                                                               |██
|                                                                               |██
|                                                                               |██
|                          Copyright (c) 2015 Tong Guo                          |██
|                                                                               |██
|                              ALL RIGHTS RESERVED.                             |██
|                                                                               |██
└===============================================================================┘██
  █████████████████████████████████████████████████████████████████████████████████
  ███████████████████████████████████████████████████████████████████████████████*/

#import <objc/runtime.h>

#import "WSCKeychain.h"
#import "WSCKeychainItem.h"
#import "WSCKeychainError.h"
#import "_WSCKeychainErrorPrivate.h"

NSString* const WSCKeychainCannotBeDirectoryErrorDescription        = @"The URL of a keychain file cannot be a directory.";
NSString* const WSCKeychainIsInvalidErrorDescription                = @"Current keychain is no longer valid, it may has been deleted, moved or renamed.";
NSString* const WSCKeychainFileExistsErrorDescription               = @"The keychain couldn't be created because a file with the same name already exists.";
NSString* const WSCKeychainURLIsInvalidErrorDescription             = @"The keychain couldn’t be created because the URL is invalid.";
NSString* const WSCCommonInvalidParametersErrorDescription          = @"One or more parameters passed to the method were not valid.";
NSString* const WSCKeychainItemIsInvalidErrorDescription            = @"Current keychain item is no longer valid, it may has been deleted, or the keychain in which it residing may has been deleted, moved or renamed.";
NSString* const WSCKeychainItemAttributeIsUniqueToInternetPassphraseErrorDescription    = @"The specified attribute was not be supported since this attribute is unique to the Internet passphrase.";
NSString* const WSCKeychainItemAttributeIsUniqueToApplicationPassphraseErrorDescription = @"The specified attribute was not be supported since this attribute is unique to the application passphrase.";
NSString* const WSCKeychainItemPermissionDeniedErrorDescription     = @"Do not have permission to access the secret data of keychain item.";
NSString* const WSCPermittedOperationFailedToChangeTheOwnerOfPermittedOperationErrorDescription = @"An invalid attempt to change the owner of a permitted operation entry.";

id const s_guard = ( id )'sgrd';
void _WSCDontBeABitch( NSError** _Error, ... )
    {
    if ( !_Error )
        return;

    /* The form of variable arguments list:
       &_Error, argToBeChecked_0(id), typeOfArg_0([ argToBeChecked_0 class ])
              , argToBeChecked_1(id), typeOfArg_1([ argToBeChecked_1 class ])
              , argToBeChecked_2(id), typeOfArg_2([ argToBeChecked_2 class ])
              ...
              , s_guard 
     */
    va_list variableArguments;

    va_start( variableArguments, _Error );
    while ( true )
        {
        // The argument we want to check
        id argToBeChecked = va_arg( variableArguments, id );

        // Check to see if we have reached the end of variable arguments list
        if ( argToBeChecked == s_guard )
            break;

        Class paramClass = va_arg( variableArguments, Class );
        // The argToBeChecked must not be nil
        if ( !argToBeChecked
                // and it must be kind of paramClass
                || ![ argToBeChecked isKindOfClass: paramClass ] )
            {
            *_Error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                           code: WSCCommonInvalidParametersError
                                       userInfo: nil ];
            // Short-circuit test:
            // we have encountered an error, so there is no necessary to proceed checking
            break;
            }

        // If argToBeChecked is a keychain, it must not be invalid
        if ( [ argToBeChecked isKindOfClass: [ WSCKeychain class ] ] &&  !( ( WSCKeychain* )argToBeChecked ).isValid )
            {
            *_Error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                           code: WSCKeychainIsInvalidError
                                       userInfo: nil ];
            break;
            }

        if ( [ argToBeChecked isKindOfClass: [ WSCKeychainItem class ] ] && !( ( WSCKeychainItem* )argToBeChecked ).isValid )
            {
            *_Error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                           code: WSCKeychainItemIsInvalidError
                                       userInfo: nil ];
            break;
            }
        }

    va_end( variableArguments );
    }

@implementation NSError ( WSCKeychainError )

+ ( NSError* ) alternative_errorWithDomain: ( NSString* )_ErrorDomain
                                      code: ( NSInteger )_ErrorCode
                                  userInfo: ( NSDictionary* )_UserInfo
    {
    NSMutableDictionary* newUserInfo = [ [ _UserInfo mutableCopy ] autorelease ];

    /* We should only perform bellow operations for the errors which in WaxSealCoreErrorDomain */
    if ( [ _ErrorDomain isEqualToString: WaxSealCoreErrorDomain ]
            /* and the user did not provide a value for the NSLocalizedDescriptionKey key in _UserInfo dictionary
             * while they invoke +[ NSError errorWithDomain:code:userInfo: ] class method */
            && !newUserInfo[ NSLocalizedDescriptionKey ] )
        {
        if ( !newUserInfo )
            /* If the _UserInfo dictionary is empty at all
             * while user invoke +[ NSError errorWithDomain:code:userInfo: ] class method */
            newUserInfo = [ NSMutableDictionary dictionaryWithCapacity: 1 ];

        switch ( _ErrorCode )
            {
            /* The URL of a keychain file cannot be a directory. */
            case WSCKeychainCannotBeDirectoryError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainCannotBeDirectoryErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainCannotBeDirectoryErrorDescription;
                } break;

            /* Current keychain is no longer valid. */
            case WSCKeychainIsInvalidError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainIsInvalidErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainIsInvalidErrorDescription;
                } break;

            /* The keychain couldn't be created because a file with the same name already exists. */
            case WSCKeychainFileExistsError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainFileExistsErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainFileExistsErrorDescription;
                } break;

            /* The keychain couldn’t be created because the URL is invalid. */
            case WSCKeychainURLIsInvalidError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainURLIsInvalidErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainURLIsInvalidErrorDescription;
                } break;

            /* One or more parameters passed to the method were not valid. */
            case WSCCommonInvalidParametersError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCCommonInvalidParametersErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCCommonInvalidParametersErrorDescription;
                } break;

            case WSCKeychainItemIsInvalidError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainItemIsInvalidErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainItemIsInvalidErrorDescription;
                } break;

            case WSCKeychainItemAttributeIsUniqueToInternetPassphraseError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainItemAttributeIsUniqueToInternetPassphraseErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainItemAttributeIsUniqueToInternetPassphraseErrorDescription;
                } break;

            case WSCKeychainItemAttributeIsUniqueToApplicationPassphraseError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainItemAttributeIsUniqueToApplicationPassphraseErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainItemAttributeIsUniqueToApplicationPassphraseErrorDescription;
                } break;

            case WSCKeychainItemPermissionDeniedError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCKeychainItemPermissionDeniedErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCKeychainItemPermissionDeniedErrorDescription;
                } break;

            case WSCPermittedOperationFailedToChangeTheOwnerOfPermittedOperationError:
                {
                newUserInfo[ NSLocalizedDescriptionKey ] =
                    _UserInfo[ NSLocalizedFailureReasonErrorKey ]
                        ? [ NSString stringWithFormat: @"%@ %@", WSCPermittedOperationFailedToChangeTheOwnerOfPermittedOperationErrorDescription
                                                               , _UserInfo[ NSLocalizedFailureReasonErrorKey ] ]
                        : WSCPermittedOperationFailedToChangeTheOwnerOfPermittedOperationErrorDescription;
                } break;
            }
        }

    // If the error lies in other error domains such as NSCocoaErrorDomain or NSOSStatusErrorDomain,
    // or the error does lie in WaxSealCoreErrorDomain but the user explicitly provide a value
    // for NSLocalizedDescriptionKey in _UserInfo dictionary, do nothing.

    return [ [ self class ] alternative_errorWithDomain: _ErrorDomain
                                                   code: _ErrorCode
                                               userInfo: newUserInfo ];
    }

@end // NSError + WSCKeychainError

__attribute__( ( constructor ) )
static void s_exchangeErrorFactoryIMPHack()
    {
    Method errorFactoryMethod = class_getClassMethod( [ NSError class ], @selector( errorWithDomain:code:userInfo: ) );
    Method alternativeErrorFactoryMethod = class_getClassMethod( [ NSError class ], @selector( alternative_errorWithDomain:code:userInfo: ) );

    // A little hack
    method_exchangeImplementations( errorFactoryMethod, alternativeErrorFactoryMethod );
    }

/*================================================================================┐
|                              The MIT License (MIT)                              |
|                                                                                 |
|                           Copyright (c) 2015 Tong Guo                           |
|                                                                                 |
|  Permission is hereby granted, free of charge, to any person obtaining a copy   |
|  of this software and associated documentation files (the "Software"), to deal  |
|  in the Software without restriction, including without limitation the rights   |
|    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    |
|      copies of the Software, and to permit persons to whom the Software is      |
|            furnished to do so, subject to the following conditions:             |
|                                                                                 |
| The above copyright notice and this permission notice shall be included in all  |
|                 copies or substantial portions of the Software.                 |
|                                                                                 |
|   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    |
|    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     |
|   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   |
|     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      |
|  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  |
|  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  |
|                                    SOFTWARE.                                    |
└================================================================================*/