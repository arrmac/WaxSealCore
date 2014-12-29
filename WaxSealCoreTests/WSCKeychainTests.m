///:
/*****************************************************************************
 **                                                                         **
 **                               .======.                                  **
 **                               | INRI |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                      .========'      '========.                         **
 **                      |   _      xxxx      _   |                         **
 **                      |  /_;-.__ / _\  _.-;_\  |                         **
 **                      |     `-._`'`_/'`.-'     |                         **
 **                      '========.`\   /`========'                         **
 **                               | |  / |                                  **
 **                               |/-.(  |                                  **
 **                               |\_._\ |                                  **
 **                               | \ \`;|                                  **
 **                               |  > |/|                                  **
 **                               | / // |                                  **
 **                               | |//  |                                  **
 **                               | \(\  |                                  **
 **                               |  ``  |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                   \\    _  _\\| \//  |//_   _ \// _                     **
 **                  ^ `^`^ ^`` `^ ^` ``^^`  `^^` `^ `^                     **
 **                                                                         **
 **                       Copyright (c) 2014 Tong G.                        **
 **                          ALL RIGHTS RESERVED.                           **
 **                                                                         **
 ****************************************************************************/

#import <XCTest/XCTest.h>

#import "WSCKeychain.h"
#import "NSURL+WSCKeychainURL.h"
#import "WSCKeychainConstants.h"

// --------------------------------------------------------
#pragma mark Interface of WSCKeychainTests case
// --------------------------------------------------------
@interface WSCKeychainTests : XCTestCase
    {
@private
    WSCKeychain*    _publicKeychain;

    NSFileManager*  _defaultFileManager;
    NSString*       _passwordForTest;

    /* Collection of random URLs been generated by -[ WSCKeychainTests randomURLForKeychain ] method
     * we will clear it in -[ WSCKeychainTests tearDown ] method
     */
    NSMutableSet*   _randomURLsAutodeletePool;
    }

@property ( nonatomic, retain ) WSCKeychain* publicKeychain;

@property ( nonatomic, unsafe_unretained ) NSFileManager* defaultFileManager;
@property ( nonatomic, copy ) NSString* passwordForTest;

@property ( nonatomic, retain ) NSMutableSet* randomURLsAutodeletePool;

@end

// --------------------------------------------------------
#pragma mark Interface of Utilities for Easy to Test
// --------------------------------------------------------
@interface WSCKeychainTests ( WSCEasyToTest )

- ( NSURL* ) randomURLForKeychain;

- ( WSCKeychain* ) randomKeychain;

- ( NSURL* ) URLForTestCase: ( SEL )_Selector
                 doesPrompt: ( BOOL )_DoesPrompt
               deleteExists: ( BOOL )_DeleteExits;

- ( BOOL ) moveKeychain: ( WSCKeychain* )_Keychain
                  toURL: ( NSURL* )_DstURL
                  error: ( NSError** )_Error;

@end // WSCKeychainTests + WSCEasyToTest

// --------------------------------------------------------
#pragma mark Implementation of WSCKeychainTests case
// --------------------------------------------------------
@implementation WSCKeychainTests

@synthesize publicKeychain = _publicKeychain;
@synthesize defaultFileManager = _defaultFileManager;
@synthesize passwordForTest = _passwordForTest;

@synthesize randomURLsAutodeletePool = _randomURLsAutodeletePool;

- ( void ) setUp
    {
    NSError* error = nil;

    if ( error )
        NSLog( @"%@", error );

    self.defaultFileManager = [ NSFileManager defaultManager ];
    self.passwordForTest = @"waxsealcore";

    NSURL* URLForPublicKeychain = [ self URLForTestCase: _cmd doesPrompt: NO deleteExists: NO ];
    /* If the the public keychain is not already exists, create one */
    if ( ![ URLForPublicKeychain checkResourceIsReachableAndReturnError: &error ] )
        {
        self.publicKeychain = [ WSCKeychain keychainWithURL: URLForPublicKeychain
                                                   password: self.passwordForTest
                                             doesPromptUser: NO
                                              initialAccess: nil
                                             becomesDefault: NO
                                                      error: &error ];
        }
    else  /* If it's already here, open it */
        {
        self.publicKeychain = [ WSCKeychain keychainWithContentsOfURL: URLForPublicKeychain
                                                                error: &error ];
        if ( error )
            NSLog( @"%@", error );
        }

    self.randomURLsAutodeletePool = [ NSMutableSet set ];
    }

- ( void ) testGetPathOfKeychain
    {
    NSError* error = nil;

    // ----------------------------------------------------------------------------------
    // Test Case 1
    // ----------------------------------------------------------------------------------
    [ self.publicKeychain setDefault: YES error: nil ];
    SecKeychainRef defaultKeychain_testCase1 = NULL;
    SecKeychainCopyDefault( &defaultKeychain_testCase1 );
    NSString* pathOfDefaultKeychain_testCase1 = WSCKeychainGetPathOfKeychain( defaultKeychain_testCase1 );
    NSLog( @"pathOfDefaultKeychain_testCase1: %@", pathOfDefaultKeychain_testCase1 );
    XCTAssertTrue( [ WSCKeychain keychainWithSecKeychainRef: defaultKeychain_testCase1 ].isValid );
    XCTAssertNotNil( pathOfDefaultKeychain_testCase1 );
    XCTAssertEqualObjects( pathOfDefaultKeychain_testCase1, [ WSCKeychain currentDefaultKeychain ].URL.path );

    // ----------------------------------------------------------------------------------
    // Test case 2
    // ----------------------------------------------------------------------------------
    SecKeychainRef login_testCase2 = [ WSCKeychain login ].secKeychain;
    NSString* pathOfLogin_testCase2 = WSCKeychainGetPathOfKeychain( login_testCase2 );
    NSLog( @"pathOfLogin_testCase2: %@", pathOfLogin_testCase2 );
    XCTAssertTrue( [ WSCKeychain keychainWithSecKeychainRef: login_testCase2 ].isValid );
    XCTAssertNotNil( pathOfLogin_testCase2 );
    XCTAssertEqualObjects( pathOfLogin_testCase2, [ WSCKeychain login ].URL.path );

    // ----------------------------------------------------------------------------------
    // Test Case 3
    // ----------------------------------------------------------------------------------
    SecKeychainRef system_testCase3 = [ WSCKeychain system ].secKeychain;
    NSString* pathOfSystem_testCase3 = WSCKeychainGetPathOfKeychain( system_testCase3 );
    NSLog( @"pathOfSystem_testCase3: %@", pathOfSystem_testCase3 );
    XCTAssertTrue( [ WSCKeychain keychainWithSecKeychainRef: system_testCase3 ].isValid );
    XCTAssertNotNil( pathOfSystem_testCase3 );
    XCTAssertEqualObjects( pathOfSystem_testCase3, [ WSCKeychain system ].URL.path );

    // ----------------------------------------------------------------------------------
    // Negative Test Case 1
    // ----------------------------------------------------------------------------------
    SecKeychainRef nil_negativeTestCase1 = nil;
    NSString* pathOfNil_negativeTestCase1 = WSCKeychainGetPathOfKeychain( nil_negativeTestCase1 );
    NSLog( @"pathOfSystem_testCase3: %@", pathOfNil_negativeTestCase1 );
    XCTAssertFalse( [ WSCKeychain keychainWithSecKeychainRef: nil_negativeTestCase1 ].isValid );
    XCTAssertNil( pathOfNil_negativeTestCase1 );
    XCTAssertEqualObjects( pathOfNil_negativeTestCase1, nil );

    // ----------------------------------------------------------------------------------
    // Negative Test Case 2
    // ----------------------------------------------------------------------------------
    NSURL* randomURL_negativeTestCase2 = [ self randomURLForKeychain ];
    WSCKeychain* randomKeychain_negativeTest2 = [ WSCKeychain keychainWithURL: randomURL_negativeTestCase2
                                                       password: self.passwordForTest
                                                 doesPromptUser: NO
                                                  initialAccess: nil
                                                 becomesDefault: NO
                                                          error: &error ];
    XCTAssertNil( error );
    if ( error ) NSLog( @"%@", error );
    [ randomKeychain_negativeTest2 setDefault: YES error: nil ];

    XCTAssertTrue( randomKeychain_negativeTest2.isValid );
    /* This keychain has be invalid */
    [ [ NSFileManager defaultManager ] removeItemAtURL: randomURL_negativeTestCase2 error: nil ];
    XCTAssertFalse( randomKeychain_negativeTest2.isValid );

    /* This is the difference between nagative test case 2 and case 3: */
    SecKeychainRef invalidDefault_negativeTestCase2 = [ WSCKeychain currentDefaultKeychain ].secKeychain;
    NSString* pathOfInvalidDefault_negativeTestCase2 = WSCKeychainGetPathOfKeychain( invalidDefault_negativeTestCase2 );
    NSLog( @"pathOfInvalidDefault_negativeTestCase2: %@", pathOfInvalidDefault_negativeTestCase2 );
    XCTAssertNil( pathOfInvalidDefault_negativeTestCase2 );

    // ----------------------------------------------------------------------------------
    // Negative Test Case 3
    // ----------------------------------------------------------------------------------
    NSURL* randomURL_negativeTestCase3 = [ self randomURLForKeychain ];
    WSCKeychain* randomKeychain_negativeTest3 = [ WSCKeychain keychainWithURL: randomURL_negativeTestCase3
                                                                     password: self.passwordForTest
                                                               doesPromptUser: NO
                                                                initialAccess: nil
                                                               becomesDefault: NO
                                                                        error: &error ];
    XCTAssertNil( error );
    if ( error ) NSLog( @"%@", error );
    [ randomKeychain_negativeTest3 setDefault: YES error: nil ];

    XCTAssertTrue( randomKeychain_negativeTest3.isValid );
    /* This keychain has be invalid */
    [ [ NSFileManager defaultManager ] removeItemAtURL: randomURL_negativeTestCase3 error: nil ];
    XCTAssertFalse( randomKeychain_negativeTest3.isValid );

    /* This is the difference between nagative test case 3 and case 2: */
    SecKeychainRef invalidDefault_negativeTestCase3 = randomKeychain_negativeTest3.secKeychain;
    NSString* pathOfInvalidDefault_negativeTestCase3 = WSCKeychainGetPathOfKeychain( invalidDefault_negativeTestCase3 );
    NSLog( @"pathOfInvalidDefault_negativeTestCase3: %@", pathOfInvalidDefault_negativeTestCase3 );
    XCTAssertNil( pathOfInvalidDefault_negativeTestCase3 );
    }

- ( void ) tearDown
    {
    [ [ WSCKeychain login ] setDefault: YES error: nil ];

    for ( NSURL* _URL in self.randomURLsAutodeletePool )
        if ( [ _URL checkResourceIsReachableAndReturnError: nil ] )
            [ [ NSFileManager defaultManager ] removeItemAtURL: _URL error: nil ];

    [ self.publicKeychain release ];
    [ self.passwordForTest release ];
    [ self.randomURLsAutodeletePool release ];
    }

// -----------------------------------------------------------------
    #pragma Test the Programmatic Interfaces for Creating Keychains
// -----------------------------------------------------------------
- ( void ) testPublicAPIsForCreatingKeychains
    {

    }

- ( void ) testURLPropeties
    {
    NSError* error = nil;

    // ----------------------------------------------------------------------------------
    // Test Case 0
    // ----------------------------------------------------------------------------------
    NSURL* URLForKeychain_test1 = [ self.publicKeychain URL ];

    NSLog( @"Path for self.publicKeychain: %@", URLForKeychain_test1 );
    XCTAssertNotNil( URLForKeychain_test1 );

    // ----------------------------------------------------------------------------------
    // Test Case 1
    // ----------------------------------------------------------------------------------
    NSURL* URLForKeychain_test2 = [ [ WSCKeychain currentDefaultKeychain: &error ] URL ];

    NSLog( @"Path for current default keychain: %@", URLForKeychain_test2 );
    XCTAssertNotNil( URLForKeychain_test2 );
    XCTAssertNil( error );

    // ----------------------------------------------------------------------------------
    // Negative Test Case 0
    // ----------------------------------------------------------------------------------
    NSURL* randomURL_negativeTestCase1 = [ self randomURLForKeychain ];
    WSCKeychain* randomKeychain_negativeTestCase1 = [ WSCKeychain keychainWithURL: randomURL_negativeTestCase1
                                                                     password: self.passwordForTest
                                                               doesPromptUser: NO
                                                                initialAccess: nil
                                                               becomesDefault: NO
                                                                        error: &error ];
    XCTAssertNil( error );
    if ( error ) NSLog( @"%@", error );
    [ randomKeychain_negativeTestCase1 setDefault: YES error: nil ];

    /* This keychain has be invalid */
    [ [ NSFileManager defaultManager ] removeItemAtURL: randomURL_negativeTestCase1 error: nil ];
    XCTAssertNil( [ WSCKeychain currentDefaultKeychain ] );
    XCTAssertNil( randomKeychain_negativeTestCase1.URL );
    }

- ( void ) testLoginClassMethod
    {
    NSError* error = nil;

    WSCKeychain* login_test1 = [ WSCKeychain login ];
    XCTAssertNotNil( login_test1 );

    [ login_test1 setDefault: YES error: &error ];

    if ( error )
        NSLog( @"%@", error );

    XCTAssertNil( error );
    }

- ( void ) testSystemClassMethod
    {
    NSError* error = nil;

    WSCKeychain* system_test1 = [ WSCKeychain system ];
    XCTAssertNotNil( system_test1 );
    NSLog( @"%@", system_test1.URL );
    XCTAssertEqualObjects( system_test1.URL, [ NSURL URLWithString: @"file:///Library/Keychains/System.keychain" ] );

    if ( error )
        NSLog( @"%@", error );

    XCTAssertNil( error );
    }

- ( void ) testClassMethodsForOpenKeychains
    {
    NSError* error = nil;

    // ----------------------------------------------------------------------------------
    // The URL location of login.keychain. (/Users/${USER_NAME}/Keychains/login.keychain)
    // ----------------------------------------------------------------------------------
    NSURL* correctURLForTestCase1 = [ NSURL sharedURLForLoginKeychain ];
    WSCKeychain* correctKeychain_test1 = [ WSCKeychain keychainWithContentsOfURL: correctURLForTestCase1
                                                                           error: &error ];
    if ( error ) NSLog( @"%@", error );
    XCTAssertNil( error );
    XCTAssertNotNil( correctKeychain_test1 );

    // ------------------------------------------------------------------------------------
    // The URL location of system.keychain. (/Users/${USER_NAME}/Keychains/system.keychain)
    // ------------------------------------------------------------------------------------
    NSURL* correctURLForTestCase2 = [ NSURL sharedURLForSystemKeychain ];
    WSCKeychain* correctKeychain_test2 = [ WSCKeychain keychainWithContentsOfURL: correctURLForTestCase2
                                                                           error: &error ];
    if ( error ) NSLog( @"%@", error );
    XCTAssertNil( error );
    XCTAssertNotNil( correctKeychain_test2 );

    // ------------------------------------------------------------------------------------
    // The URL location is completely wrong. Hum...it's not a URL at all.
    // ------------------------------------------------------------------------------------
    NSURL* incorrectURLForNagativeTestCase1 = [ NSURL URLWithString: @"completelyWrong" ];
    WSCKeychain* incorrectKeychain_nagativeTestCase1 = [ WSCKeychain keychainWithContentsOfURL: incorrectURLForNagativeTestCase1
                                                                                         error: &error ];
    if ( error ) NSLog( @"%@", error );
    XCTAssertNotNil( error );
    XCTAssertEqualObjects( error.domain, NSCocoaErrorDomain );
    XCTAssertEqual( error.code, NSFileNoSuchFileError );
    XCTAssertNil( incorrectKeychain_nagativeTestCase1 );

    // ------------------------------------------------------------------------------------
    // The URL location is not completely wrong, however the format is incorrect.
    // ------------------------------------------------------------------------------------
    NSURL* incorrectURLForNagativeTestCase2 = [ NSURL URLWithString:
        [ NSString stringWithFormat: @"%@/Library/Keychains/login.keychain", NSHomeDirectory() ] ];
    WSCKeychain* incorrectKeychain_nagativeTestCase2 = [ WSCKeychain keychainWithContentsOfURL: incorrectURLForNagativeTestCase2
                                                                                         error: &error ];
    if ( error ) NSLog( @"%@", error );
    XCTAssertNotNil( error );
    XCTAssertEqualObjects( error.domain, NSCocoaErrorDomain );
    XCTAssertEqual( error.code, NSFileNoSuchFileError );
    XCTAssertNil( incorrectKeychain_nagativeTestCase2 );

    // ----------------------------------------------------------------------------------------------------------
    // The URL location is a directory instead of file with .keychain extention, however the format is incorrect.
    // ----------------------------------------------------------------------------------------------------------
    WSCKeychain* incorrectKeychain_negativeTestCase3 = [ WSCKeychain keychainWithContentsOfURL: [ NSURL sharedURLForCurrentUserKeychainsDirectory ]
                                                                                         error: &error ];
    if ( error ) NSLog( @"%@", error );
    XCTAssertNotNil( error );
    XCTAssertEqualObjects( error.domain, WSCKeychainErrorDomain );
    XCTAssertEqual( error.code, WSCKeychainCannotBeDirectory );
    XCTAssertNil( incorrectKeychain_negativeTestCase3 );
    }

- ( void ) testPrivateAPIsForCreatingKeychains
    {
    OSStatus resultCode = errSecSuccess;

    /* URL of keychain for test case 1
     * Destination location: /var/folders/fv/k_p7_fbj4fzbvflh4905fn1m0000gn/T/NSTongG_nonPrompt....keychain
     */
    NSURL* URLForNewKeychain_nonPrompt = [ self URLForTestCase: _cmd doesPrompt: NO deleteExists: YES ];

    /* URL of keychain for test case 2
     * Destination location: /var/folders/fv/k_p7_fbj4fzbvflh4905fn1m0000gn/T/NSTongG_withPrompt....keychain
     */
    NSURL* URLForNewKeychain_withPrompt = [ self URLForTestCase: _cmd doesPrompt: YES deleteExists: YES ];

    // Create sec keychain for test case 1
    SecKeychainRef secKeychain_nonPrompt = NULL;
    resultCode = SecKeychainCreate( [ URLForNewKeychain_nonPrompt.path UTF8String ]
                                  , ( UInt32)[ self.passwordForTest length ], [ self.passwordForTest UTF8String ]
                                  , NO
                                  , nil
                                  , &secKeychain_nonPrompt
                                  );

    // Create sec keychain for test case 2
    SecKeychainRef secKeychain_withPrompt = NULL;
    resultCode = SecKeychainCreate( [ URLForNewKeychain_withPrompt.path UTF8String ]
                                  , ( UInt32)[ self.passwordForTest length ], [ self.passwordForTest UTF8String ]
                                  , YES
                                  , nil
                                  , &secKeychain_withPrompt
                                  );

    // Create WSCKeychain for test case 1
    WSCKeychain* keychain_nonPrompt = [ [ [ WSCKeychain alloc ] p_initWithSecKeychainRef: secKeychain_nonPrompt ] autorelease ];
    // Create WSCKeychain for test case 2
    WSCKeychain* keychain_withPrompt = [ [ [ WSCKeychain alloc ] p_initWithSecKeychainRef: secKeychain_withPrompt ] autorelease ];
    // Create WSCKeychain for test case 3 (negative testing)
    WSCKeychain* keychain_negativeTesting = [ [ [ WSCKeychain alloc ] p_initWithSecKeychainRef: nil ] autorelease ];

    XCTAssertNotNil( keychain_nonPrompt );
    XCTAssertNotNil( keychain_withPrompt );
    XCTAssertNil( keychain_negativeTesting );

    if ( secKeychain_nonPrompt )
        CFRelease( secKeychain_nonPrompt );

    if ( secKeychain_withPrompt )
        CFRelease( secKeychain_withPrompt );
    }

// -----------------------------------------------------------------
    #pragma Test the Programmatic Interfaces for Managing Keychains
// -----------------------------------------------------------------
- ( void ) testPublicAPIsForManagingKeychains
    {
    NSError* error = nil;

    WSCKeychain* currentDefaultKeychain_testCase1 = [ WSCKeychain currentDefaultKeychain ];
    WSCKeychain* currentDefaultKeychain_testCase2 = [ WSCKeychain currentDefaultKeychain: &error ];

    XCTAssertNotNil( currentDefaultKeychain_testCase1 );

    XCTAssertNotNil( currentDefaultKeychain_testCase2 );
    XCTAssertNil( error );

    OSStatus resultCode = SecKeychainSetDefault( NULL );
    WSCPrintError( resultCode );

    // TODO: Waiting for a nagtive testing.
    }

- ( void ) testSetDefaultMethods
    {
    NSError* error = nil;

    // ------------------------------------------------------------------------------------
    // Test case 0
    // ------------------------------------------------------------------------------------
    [ [ WSCKeychain login ] setDefault: YES error: &error ];
    XCTAssertNil( error, @"Error occured while setting the login.keychain back as default!" );
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], [ WSCKeychain login ] );

    // ------------------------------------------------------------------------------------
    // Test case 1
    // ------------------------------------------------------------------------------------
    NSURL* URLForNewKeychain_testCase1 = [ self URLForTestCase: _cmd doesPrompt: NO deleteExists: YES ];
    WSCKeychain* newKeychain_testCase1 = [ WSCKeychain keychainWithURL: URLForNewKeychain_testCase1
                                                              password: self.passwordForTest
                                                        doesPromptUser: NO
                                                         initialAccess: nil
                                                        becomesDefault: NO
                                                                 error: &error ];

    XCTAssertNil( error, @"Error occured while creating the new keychain!" );
    XCTAssertNotNil( newKeychain_testCase1 );
    XCTAssertTrue( newKeychain_testCase1.isValid );

    [ newKeychain_testCase1 setDefault: YES error: &error ];
    XCTAssertNil( error, @"Error occured while setting the new keychain as default!" );
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], newKeychain_testCase1 );
    [ newKeychain_testCase1 setDefault: NO error: &error ];
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], [ WSCKeychain login ] );

    // ------------------------------------------------------------------------------------
    // Test case 2
    // ------------------------------------------------------------------------------------
    NSURL* URLForNewKeychain_testCase2 = [ self randomURLForKeychain ];
    NSLog( @"URLForNewKeychain_testCase2: %@", URLForNewKeychain_testCase2 );
    WSCKeychain* newKeychain_testCase2 = [ WSCKeychain keychainWithURL: URLForNewKeychain_testCase2
                                                              password: self.passwordForTest
                                                        doesPromptUser: NO
                                                         initialAccess: nil
                                                        becomesDefault: NO
                                                                 error: &error ];

    [ newKeychain_testCase2 setDefault: NO error: &error ];
    XCTAssertNil( error, @"Error occured while setting the new keychain as default!" );
    XCTAssertTrue( newKeychain_testCase2.isValid );
    XCTAssertNotEqualObjects( [ WSCKeychain currentDefaultKeychain ], newKeychain_testCase2 );

    // ------------------------------------------------------------------------------------
    // Test case 3
    // ------------------------------------------------------------------------------------
    NSURL* URLForNewKeychain_testCase3 = [ self randomURLForKeychain ];
    WSCKeychain* newKeychain_testCase3 = [ WSCKeychain keychainWithURL: URLForNewKeychain_testCase3
                                                              password: self.passwordForTest
                                                        doesPromptUser: NO
                                                         initialAccess: nil
                                                        becomesDefault: NO
                                                                 error: &error ];

    [ newKeychain_testCase3 setDefault: YES error: &error ];
    XCTAssertNil( error, @"Error occured while setting the new keychain as default!" );
    XCTAssertTrue( newKeychain_testCase3.isValid );
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], newKeychain_testCase3 );

    // ------------------------------------------------------------------------------------
    // Test case 4
    // ------------------------------------------------------------------------------------
    NSURL* URLForNewKeychain_testCase4 = [ self randomURLForKeychain ];
    WSCKeychain* newKeychain_testCase4 = [ WSCKeychain keychainWithURL: URLForNewKeychain_testCase4
                                                              password: self.passwordForTest
                                                        doesPromptUser: NO
                                                         initialAccess: nil
                                                        becomesDefault: NO
                                                                 error: &error ];
    [ newKeychain_testCase4 setDefault: YES error: &error ];
    XCTAssertNil( error, @"Error occured while setting the new keychain as default!" );
    XCTAssertTrue( newKeychain_testCase4.isValid );
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], newKeychain_testCase4 );

    // ------------------------------------------------------------------------------------
    // Test case 5
    // ------------------------------------------------------------------------------------
    [ [ WSCKeychain login ] setDefault: YES error: &error ];
    XCTAssertNil( error, @"Error occured while setting the login.keychain back as default!" );
    XCTAssertEqualObjects( [ WSCKeychain currentDefaultKeychain ], [ WSCKeychain login ] );

    // ------------------------------------------------------------------------------------
    // Negative Test case 0
    // ------------------------------------------------------------------------------------
    /* Now the login.keychain is already default */
    XCTAssertTrue( [ WSCKeychain currentDefaultKeychain ].isValid );
    [ [ WSCKeychain login ] setDefault: NO error: &error ];
    [ [ WSCKeychain login ] setDefault: NO error: &error ];
    XCTAssertFalse( [ WSCKeychain currentDefaultKeychain ].isValid );

    XCTAssertNil( error, @"Error occured while setting the login.keychain back as default!" );
    XCTAssertNotEqualObjects( [ WSCKeychain currentDefaultKeychain ], [ WSCKeychain login ] );
    NSLog( @"Current Default URL: %@", [ WSCKeychain currentDefaultKeychain ].URL );
    NSLog( @"Current Default: %@", [ WSCKeychain currentDefaultKeychain ] );
    XCTAssertNil( [ WSCKeychain currentDefaultKeychain ] );
    [ [ WSCKeychain login ] setDefault: YES error: &error ];
    XCTAssertNil( error );
    XCTAssertNotNil( [ WSCKeychain currentDefaultKeychain ] );
    XCTAssertEqualObjects( [ WSCKeychain login ], [ WSCKeychain currentDefaultKeychain ] );

    // ------------------------------------------------------------------------------------
    // Negative Test case 1
    // ------------------------------------------------------------------------------------
    [ [ WSCKeychain system ] setDefault: YES error: &error ];
    XCTAssertNotNil( [ WSCKeychain currentDefaultKeychain ] );
    XCTAssertNotNil( error );
    XCTAssertNotNil( [ WSCKeychain currentDefaultKeychain ] );
    NSLog( @"%@", error );
    }

- ( void ) testIsValid
    {
    /* Test in testGetPathOfKeychain(), testSetDefaultMethods() etc... */
    }

- ( void ) testEquivalent
    {
    WSCKeychain* keychainForTestCase1 = [ WSCKeychain login ];
    WSCKeychain* keychainForTestCase2 = [ WSCKeychain login ];
    WSCKeychain* keychainForTestCase3 = [ WSCKeychain login ];
    WSCKeychain* keychainForTestCase4 = self.publicKeychain;

    NSLog( @"Case 1: %p     %lu", keychainForTestCase1, keychainForTestCase1.hash );
    NSLog( @"Case 2: %p     %lu", keychainForTestCase2, keychainForTestCase2.hash );
    NSLog( @"Case 3: %p     %lu", keychainForTestCase3, keychainForTestCase3.hash );
    NSLog( @"Case 4: %p     %lu", keychainForTestCase4, keychainForTestCase4.hash );

    XCTAssertNotEqual( keychainForTestCase1, keychainForTestCase2 );
    XCTAssertNotEqual( keychainForTestCase2, keychainForTestCase3 );
    XCTAssertNotEqual( keychainForTestCase3, keychainForTestCase4 );

    XCTAssertEqual( keychainForTestCase1.hash, keychainForTestCase2.hash );
    XCTAssertEqual( keychainForTestCase2.hash, keychainForTestCase3.hash );
    XCTAssertNotEqual( keychainForTestCase3.hash, keychainForTestCase4.hash );

    XCTAssertFalse( [ keychainForTestCase1 isEqualToKeychain: keychainForTestCase4 ] );
    XCTAssertTrue( [ keychainForTestCase1 isEqualToKeychain: keychainForTestCase2 ] );
    XCTAssertTrue( [ keychainForTestCase2 isEqualToKeychain: keychainForTestCase3 ] );
    XCTAssertFalse( [ keychainForTestCase3 isEqualToKeychain: keychainForTestCase4 ] );

    XCTAssertFalse( [ keychainForTestCase1 isEqual: keychainForTestCase4 ] );
    XCTAssertTrue( [ keychainForTestCase1 isEqual: keychainForTestCase2 ] );
    XCTAssertTrue( [ keychainForTestCase2 isEqual: keychainForTestCase3 ] );
    XCTAssertFalse( [ keychainForTestCase3 isEqual: keychainForTestCase4 ] );

    XCTAssertFalse( [ keychainForTestCase1 isEqual: @1 ] );
    XCTAssertFalse( [ keychainForTestCase2 isEqual: @"TestTestTest" ] );
    XCTAssertFalse( [ keychainForTestCase3 isEqual: [ NSDate date ] ] );
    XCTAssertFalse( [ keychainForTestCase4 isEqual: nil ] );

    // Self assigned
    XCTAssertTrue( [ keychainForTestCase1 isEqualToKeychain: keychainForTestCase1 ] );
    XCTAssertTrue( [ keychainForTestCase2 isEqualToKeychain: keychainForTestCase2 ] );
    XCTAssertTrue( [ keychainForTestCase3 isEqualToKeychain: keychainForTestCase3 ] );
    XCTAssertTrue( [ keychainForTestCase4 isEqualToKeychain: keychainForTestCase4 ] );

    XCTAssertTrue( [ keychainForTestCase1 isEqual: keychainForTestCase1 ] );
    XCTAssertTrue( [ keychainForTestCase2 isEqual: keychainForTestCase2 ] );
    XCTAssertTrue( [ keychainForTestCase3 isEqual: keychainForTestCase3 ] );
    XCTAssertTrue( [ keychainForTestCase4 isEqual: keychainForTestCase4 ] );
    }

- ( void ) testRandomURLForKeychain
    {
    NSURL* randomURL_testCase0 = [ self randomURLForKeychain ];
    NSURL* randomURL_testCase1 = [ self randomURLForKeychain ];
    NSURL* randomURL_testCase2 = [ self randomURLForKeychain ];
    NSURL* randomURL_testCase3 = [ self randomURLForKeychain ];
    NSURL* randomURL_testCase4 = [ self randomURLForKeychain ];

    NSLog( @"randomURL_testCase0: %@", randomURL_testCase0 );
    NSLog( @"randomURL_testCase1: %@", randomURL_testCase1 );
    NSLog( @"randomURL_testCase2: %@", randomURL_testCase2 );
    NSLog( @"randomURL_testCase3: %@", randomURL_testCase3 );
    NSLog( @"randomURL_testCase4: %@", randomURL_testCase4 );

    XCTAssertNotEqualObjects( randomURL_testCase0, randomURL_testCase1 );
    XCTAssertNotEqualObjects( randomURL_testCase1, randomURL_testCase2 );
    XCTAssertNotEqualObjects( randomURL_testCase2, randomURL_testCase3 );
    XCTAssertNotEqualObjects( randomURL_testCase3, randomURL_testCase4 );
    XCTAssertNotEqualObjects( randomURL_testCase4, randomURL_testCase0 );
    }

- ( void ) testRandomKeychain
    {
    WSCKeychain* randomKeychain_testCase0 = [ self randomKeychain ];
    WSCKeychain* randomKeychain_testCase1 = [ self randomKeychain ];
    WSCKeychain* randomKeychain_testCase2 = [ self randomKeychain ];
    WSCKeychain* randomKeychain_testCase3 = [ self randomKeychain ];
    WSCKeychain* randomKeychain_testCase4 = [ self randomKeychain ];

    XCTAssertNotNil( randomKeychain_testCase0 );
    XCTAssertNotNil( randomKeychain_testCase1 );
    XCTAssertNotNil( randomKeychain_testCase2 );
    XCTAssertNotNil( randomKeychain_testCase3 );
    XCTAssertNotNil( randomKeychain_testCase4 );

    XCTAssertNotEqualObjects( randomKeychain_testCase0, randomKeychain_testCase1 );
    XCTAssertNotEqualObjects( randomKeychain_testCase1, randomKeychain_testCase2 );
    XCTAssertNotEqualObjects( randomKeychain_testCase2, randomKeychain_testCase3 );
    XCTAssertNotEqualObjects( randomKeychain_testCase3, randomKeychain_testCase4 );
    XCTAssertNotEqualObjects( randomKeychain_testCase4, randomKeychain_testCase0 );

    XCTAssertNotEqual( randomKeychain_testCase0.hash, randomKeychain_testCase1.hash );
    XCTAssertNotEqual( randomKeychain_testCase1.hash, randomKeychain_testCase2.hash );
    XCTAssertNotEqual( randomKeychain_testCase2.hash, randomKeychain_testCase3.hash );
    XCTAssertNotEqual( randomKeychain_testCase3.hash, randomKeychain_testCase4.hash );
    XCTAssertNotEqual( randomKeychain_testCase4.hash, randomKeychain_testCase0.hash );

    NSLog( @"%@", randomKeychain_testCase0.URL );
    NSLog( @"%@", randomKeychain_testCase1.URL );
    NSLog( @"%@", randomKeychain_testCase2.URL );
    NSLog( @"%@", randomKeychain_testCase3.URL );
    NSLog( @"%@", randomKeychain_testCase4.URL );
    }

@end // WSCKeychainTests case

// --------------------------------------------------------
#pragma mark Implementation of Utilities for Easy to Test
// --------------------------------------------------------

@implementation WSCKeychainTests ( WSCEasyToTest )

- ( NSURL* ) randomURLForKeychain
    {
    srand( ( unsigned int )time( NULL ) );

    NSString* fuckString = [ NSString stringWithFormat: @"%lu", random() ];
    NSString* keychainNameWithHash = [ NSString stringWithFormat: @"%lx.keychain"
                                                                , fuckString.hash ];

    NSURL* randomURL = [ [ NSURL URLForTemporaryDirectory ] URLByAppendingPathComponent: keychainNameWithHash ];
    [ self.randomURLsAutodeletePool addObject: [ randomURL retain ] ];

    return randomURL;
    }

- ( WSCKeychain* ) randomKeychain
    {
    NSURL* randomURL = [ self randomURLForKeychain ];
    WSCKeychain* randomKeychain = [ WSCKeychain keychainWithURL: randomURL
                                                       password: self.passwordForTest
                                                 doesPromptUser: NO
                                                  initialAccess: nil
                                                 becomesDefault: NO
                                                          error: nil ];
    return randomKeychain;
    }

- ( NSURL* ) URLForTestCase: ( SEL )_Selector
                 doesPrompt: ( BOOL )_DoesPrompt
               deleteExists: ( BOOL )_DeleteExits
    {
    NSString* keychainName = [ NSString stringWithFormat: @"WSC_%@_%@.keychain"
                                                        , _DoesPrompt ? @"withPrompt" : @"nonPrompt"
                                                        , NSStringFromSelector( _Selector ) ];

    NSURL* newURL = [ [ NSURL URLForTemporaryDirectory ] URLByAppendingPathComponent: keychainName ];

    if ( _DeleteExits )
        {
        if ( [ self.defaultFileManager fileExistsAtPath: [ newURL path ] ] )
            [ self.defaultFileManager removeItemAtURL: newURL error: nil ];
        }

    return newURL;
    }

- ( BOOL ) moveKeychain: ( WSCKeychain* )_Keychain
                  toURL: ( NSURL* )_DstURL
                  error: ( NSError** )_Error
    {
    BOOL moveSuccess = NO;

    if ( _Keychain && _DstURL )
        moveSuccess = [ [ NSFileManager defaultManager ] moveItemAtURL: _Keychain.URL
                                                                 toURL: _DstURL
                                                                 error: _Error ];
    return moveSuccess;
    }

@end // WSCKeychainTests + WSCEasyToTest

//////////////////////////////////////////////////////////////////////////////

/*****************************************************************************
 **                                                                         **
 **                                                                         **
 **      █████▒█    ██  ▄████▄   ██ ▄█▀       ██████╗ ██╗   ██╗ ██████╗     **
 **    ▓██   ▒ ██  ▓██▒▒██▀ ▀█   ██▄█▒        ██╔══██╗██║   ██║██╔════╝     **
 **    ▒████ ░▓██  ▒██░▒▓█    ▄ ▓███▄░        ██████╔╝██║   ██║██║  ███╗    **
 **    ░▓█▒  ░▓▓█  ░██░▒▓▓▄ ▄██▒▓██ █▄        ██╔══██╗██║   ██║██║   ██║    **
 **    ░▒█░   ▒▒█████▓ ▒ ▓███▀ ░▒██▒ █▄       ██████╔╝╚██████╔╝╚██████╔╝    **
 **     ▒ ░   ░▒▓▒ ▒ ▒ ░ ░▒ ▒  ░▒ ▒▒ ▓▒       ╚═════╝  ╚═════╝  ╚═════╝     **
 **     ░     ░░▒░ ░ ░   ░  ▒   ░ ░▒ ▒░                                     **
 **     ░ ░    ░░░ ░ ░ ░        ░ ░░ ░                                      **
 **              ░     ░ ░      ░  ░                                        **
 **                    ░                                                    **
 **                                                                         **
 ****************************************************************************/