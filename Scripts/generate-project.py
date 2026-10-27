#!/usr/bin/env python3
"""Generate the ordinary Xcode project with Python's standard library only."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent.parent
objects = {}

def identifier(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

def add(object_key, isa, **values):
    key = identifier(object_key)
    objects[key] = dict(isa=isa, **values)
    return key

def ref(path, kind):
    return add('file:' + path, 'PBXFileReference', lastKnownFileType=kind,
               path=path, sourceTree='SOURCE_ROOT')

sources = sorted(str(path.relative_to(root)) for folder in ['App', 'Core', 'Features', 'Components']
                 for path in (root / folder).rglob('*.swift'))
unit = sorted(str(path.relative_to(root)) for path in (root / 'Tests').glob('*Tests.swift'))
ui = ['UITests/ZeroDockUITests.swift']
resources = ['Resources/Assets.xcassets', 'Resources/ThirdPartyNotices.txt']
files = {path: ref(path, 'sourcecode.swift') for path in sources + unit + ui}
files.update({path: ref(path, 'folder.assetcatalog' if path.endswith('xcassets') else 'text') for path in resources})
for path, kind in [('Resources/Info.plist', 'text.plist.xml'), ('Resources/Release.xcconfig', 'text.xcconfig'), ('README.md', 'net.daringfireball.markdown')]:
    files[path] = ref(path, kind)

groups = []
for folder in ['App', 'Core', 'Features', 'Components', 'Resources', 'Tests', 'UITests']:
    children = [key for path, key in files.items() if path.startswith(folder + '/')]
    groups.append(add('group:' + folder, 'PBXGroup', name=folder, children=children, sourceTree='<group>'))
packages = [
    add('package:Nuke', 'XCRemoteSwiftPackageReference', repositoryURL='https://github.com/kean/Nuke.git', requirement={'kind': 'exactVersion', 'version': '12.8.0'}),
    add('package:FluidGradient', 'XCRemoteSwiftPackageReference', repositoryURL='https://github.com/Cindori/FluidGradient.git', requirement={'kind': 'exactVersion', 'version': '1.0.0'})
]
package_products = [add('packageproduct:' + name, 'XCSwiftPackageProductDependency', package=packages[index], productName=name)
                    for name, index in [('Nuke', 0), ('NukeUI', 0), ('FluidGradient', 1)]]
products = []
target_ids = {name: identifier('target:' + name) for name in ['ZeroDock', 'ZeroDockTests', 'ZeroDockUITests']}
project_id = identifier('project')

common = dict(CLANG_ENABLE_MODULES='YES', CLANG_ENABLE_OBJC_ARC='YES', SWIFT_VERSION='5.0',
              IPHONEOS_DEPLOYMENT_TARGET='17.0', SDKROOT='iphoneos', ENABLE_USER_SCRIPT_SANDBOXING='YES',
              SWIFT_STRICT_CONCURRENCY='targeted')

def configurations(name, settings, release_config=False):
    configs = []
    for mode in ['Debug', 'Release']:
        values = dict(settings)
        values.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if mode == 'Debug' else '-O',
                      DEBUG_INFORMATION_FORMAT='dwarf' if mode == 'Debug' else 'dwarf-with-dsym')
        if mode == 'Debug':
            values.update(ENABLE_TESTABILITY='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG $(inherited)')
        else:
            values['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        extra = {'baseConfigurationReference': files['Resources/Release.xcconfig']} if release_config else {}
        configs.append(add('config:' + name + mode, 'XCBuildConfiguration', name=mode, buildSettings=values, **extra))
    return add('configs:' + name, 'XCConfigurationList', buildConfigurations=configs,
               defaultConfigurationIsVisible=0, defaultConfigurationName='Release')

for name, paths, ext, product_type in [
    ('ZeroDock', sources, 'app', 'com.apple.product-type.application'),
    ('ZeroDockTests', unit, 'xctest', 'com.apple.product-type.bundle.unit-test'),
    ('ZeroDockUITests', ui, 'xctest', 'com.apple.product-type.bundle.ui-testing')]:
    product = add('product:' + name, 'PBXFileReference', explicitFileType='wrapper.application' if ext == 'app' else 'wrapper.cfbundle',
                  includeInIndex=0, path=name + '.' + ext, sourceTree='BUILT_PRODUCTS_DIR')
    products.append(product)
    builds = [add('build:' + name + path, 'PBXBuildFile', fileRef=files[path]) for path in paths]
    package_builds = [add('packagebuild:' + product, 'PBXBuildFile', productRef=product) for product in package_products] if ext == 'app' else []
    phases = [add('sources:' + name, 'PBXSourcesBuildPhase', buildActionMask=2147483647, files=builds, runOnlyForDeploymentPostprocessing=0),
              add('frameworks:' + name, 'PBXFrameworksBuildPhase', buildActionMask=2147483647, files=package_builds, runOnlyForDeploymentPostprocessing=0)]
    resource_builds = [add('resource:' + path, 'PBXBuildFile', fileRef=files[path]) for path in resources] if ext == 'app' else []
    phases.append(add('resources:' + name, 'PBXResourcesBuildPhase', buildActionMask=2147483647, files=resource_builds, runOnlyForDeploymentPostprocessing=0))
    settings = dict(PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='dev.zerodock.' + name.lower(),
                    TARGETED_DEVICE_FAMILY='1', SUPPORTED_PLATFORMS='iphoneos iphonesimulator',
                    CODE_SIGN_STYLE='Automatic', SUPPORTS_MACCATALYST='NO', SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD='NO',
                    LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks')
    dependencies = []
    if ext == 'app':
        settings.update(PRODUCT_BUNDLE_IDENTIFIER='dev.zerodock.app', INFOPLIST_FILE='Resources/Info.plist',
                        GENERATE_INFOPLIST_FILE='NO', ASSETCATALOG_COMPILER_APPICON_NAME='AppIcon')
    else:
        settings.update(GENERATE_INFOPLIST_FILE='YES')
        proxy = add('proxy:' + name, 'PBXContainerItemProxy', containerPortal=project_id,
                    proxyType=1, remoteGlobalIDString=target_ids['ZeroDock'], remoteInfo='ZeroDock')
        dependencies.append(add('dependency:' + name, 'PBXTargetDependency', target=target_ids['ZeroDock'], targetProxy=proxy))
        if name == 'ZeroDockTests':
            settings.update(TEST_HOST='$(BUILT_PRODUCTS_DIR)/ZeroDock.app/ZeroDock', BUNDLE_LOADER='$(TEST_HOST)')
        else:
            settings.update(TEST_TARGET_NAME='ZeroDock')
    add('target:' + name, 'PBXNativeTarget', buildConfigurationList=configurations(name, settings),
        buildPhases=phases, buildRules=[], dependencies=dependencies, packageProductDependencies=package_products if ext == 'app' else [], name=name,
        productName=name, productReference=product, productType=product_type)

products_group = add('group:Products', 'PBXGroup', name='Products', children=products, sourceTree='<group>')
main = add('group:main', 'PBXGroup', children=groups + [files['README.md'], products_group], sourceTree='<group>')
add('project', 'PBXProject', attributes=dict(LastUpgradeCheck='1600', TargetAttributes={target_ids[name]: dict(CreatedOnToolsVersion='16.0', **({'TestTargetID': target_ids['ZeroDock']} if name != 'ZeroDock' else {})) for name in target_ids}),
    buildConfigurationList=configurations('project', common, release_config=True), compatibilityVersion='Xcode 14.0',
    developmentRegion='en', hasScannedForEncodings=0, knownRegions=['en', 'Base'], mainGroup=main,
    productRefGroup=products_group, projectDirPath='', projectRoot='', packageReferences=packages, targets=list(target_ids.values()))

def encode(value, depth=0):
    if isinstance(value, dict):
        return '{\n' + ''.join('\t' * (depth + 1) + json.dumps(str(k)) + ' = ' + encode(v, depth + 1) + ';\n' for k, v in value.items()) + '\t' * depth + '}'
    if isinstance(value, list):
        return '(' + ', '.join(encode(v, depth) for v in value) + ')'
    return str(value) if isinstance(value, int) else json.dumps(value)

project = root / 'ZeroDock.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n' + encode(dict(archiveVersion=1, classes={}, objectVersion=56, objects=objects, rootObject=project_id)) + '\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)

def build_ref(name):
    ext = 'app' if name == 'ZeroDock' else 'xctest'
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids[name]}" BuildableName="{name}.{ext}" BlueprintName="{name}" ReferencedContainer="container:ZeroDock.xcodeproj"/>'

(schemes / 'ZeroDock.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{build_ref('ZeroDock')}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
<TestableReference skipped="NO" parallelizable="NO">{build_ref('ZeroDockTests')}</TestableReference>
<TestableReference skipped="NO" parallelizable="NO">{build_ref('ZeroDockUITests')}</TestableReference>
</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref('ZeroDock')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref('ZeroDock')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated ZeroDock.xcodeproj (app, unit tests, UI tests; NukeUI + FluidGradient)')
