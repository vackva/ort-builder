setlocal

REM Argument received: onnxruntime-1.14.1 or onnxruntime-1.16.2
set ONNXRT_FOLDER=%1
echo Argument received: %ONNXRT_FOLDER%

@set "ONNX_CONFIG=%0"
@if "%ONNX_CONFIG%"=="" (
	@set "ONNX_CONFIG=model.required_operators_and_types.config"
)
set "CMAKE_BUILD_TYPE=Debug"

mkdir "win-libs\"

"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -format value -property catalog_productLine > tmp || exit \b
set /p version= < tmp
set version=%version:Dev=%

"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -format value -property installationPath > tmp || exit \b
set /p installationPath= < tmp

"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -format value -property catalog_productLineVersion > tmp || exit \b
set /p year= < tmp

del tmp

call %ONNXRT_FOLDER%\build.bat ^
--config="%CMAKE_BUILD_TYPE%" ^
--cmake_generator="Visual Studio %version% %year%" ^
--parallel ^
--use_full_protobuf ^
--enable_msvc_static_runtime ^
--skip_tests ^
	|| exit \b

call "%installationPath%\VC\Auxiliary\Build\vcvarsall.bat" x86_x64 ^
	|| exit \b

REM Builds x64 / x86 depending on system architecture?
lib.exe /OUT:".\win-libs\\%ONNXRT_FOLDER%-win-x86_64_%CMAKE_BUILD_TYPE%.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\onnx-build\%CMAKE_BUILD_TYPE%\onnx.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\onnx-build\%CMAKE_BUILD_TYPE%\onnx_proto.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_graph.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_mlas.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_optimizer.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_providers.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_common.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_session.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_flatbuffers.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_test_utils.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_framework.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnxruntime_util.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnx_test_data_proto.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\%CMAKE_BUILD_TYPE%\onnx_test_runner_common.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\re2-build\%CMAKE_BUILD_TYPE%\re2.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\protobuf-build\%CMAKE_BUILD_TYPE%\libprotobufd.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\hash\%CMAKE_BUILD_TYPE%\absl_hash.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\hash\%CMAKE_BUILD_TYPE%\absl_city.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\hash\%CMAKE_BUILD_TYPE%\absl_low_level_hash.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\base\%CMAKE_BUILD_TYPE%\absl_throw_delegate.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\base\%CMAKE_BUILD_TYPE%\absl_raw_logging_internal.lib" ^
  ".\%ONNXRT_FOLDER%\build\Windows\%CMAKE_BUILD_TYPE%\_deps\abseil_cpp-build\absl\container\%CMAKE_BUILD_TYPE%\absl_raw_hash_set.lib"

