#**************************************************************************************************
#
#   Makefile de raylib para plataformas de escritorio, Raspberry Pi, Android y HTML5
#
#   Copyright (c) 2013-2019 Ramon Santamaria (@raysan5)
#
#   Este software se proporciona "tal cual", sin ninguna garantía expresa o implícita. En ningún caso
#   los autores serán responsables de ningún daño derivado del uso de este software.
#
#   Se concede permiso a cualquier persona para usar este software con cualquier propósito, incluidas aplicaciones comerciales,
#   y para modificarlo y redistribuirlo libremente, sujeto a las siguientes restricciones:
#
#     1. El origen de este software no debe ser mal representado; no debes afirmar que
#     escribiste el software original. Si usas este software en un producto, un reconocimiento
#     en la documentación del producto sería apreciado, pero no es obligatorio.
#
#     2. Las versiones modificadas del código fuente deben estar claramente marcadas como tales, y no deben ser mal representadas
#     como si fueran el software original.
#
#     3. Este aviso no puede ser removido ni alterado de ninguna distribución del código fuente.
#
#**************************************************************************************************

.PHONY: all clean

# Definir las variables necesarias de raylib
PROJECT_NAME       ?= game
RAYLIB_VERSION     ?= 5.0.0
RAYLIB_PATH        ?= ..\..

# Definir la ruta del compilador en Windows
COMPILER_PATH      ?= C:/raylib/w64devkit/bin

# Definir opciones predeterminadas
# Una de las siguientes: PLATFORM_DESKTOP, PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
PLATFORM           ?= PLATFORM_DESKTOP

# Ubicaciones de la biblioteca recién instalada y sus encabezados asociados. Ver ../src/Makefile.
# En Linux, si has instalado raylib pero no puedes compilar los ejemplos, verifica que
# los valores de *_INSTALL_PATH aquí sean los mismos que en src/Makefile o que apunten a ubicaciones conocidas.
# Para habilitar la vinculación en tiempo de compilación y ejecución de libraylib.so a nivel del sistema,
# ejecuta ../src/$ sudo make install RAYLIB_LIBTYPE_SHARED.
# Para habilitar la vinculación en tiempo de compilación a una versión especial de libraylib.so, cambia estas variables aquí.
# Para habilitar la vinculación en tiempo de ejecución a una versión especial de libraylib.so, consulta EXAMPLE_RUNTIME_PATH a continuación.
# Si hay un libraylib en EXAMPLE_RUNTIME_PATH y en RAYLIB_INSTALL_PATH, en tiempo de ejecución,
# la biblioteca en EXAMPLE_RUNTIME_PATH, si está presente, tendrá prioridad sobre la de RAYLIB_INSTALL_PATH.
# RAYLIB_INSTALL_PATH debería ser la ruta completa deseada a libraylib. No uses rutas relativas.
DESTDIR ?= /usr/local
RAYLIB_INSTALL_PATH ?= $(DESTDIR)/lib
# RAYLIB_H_INSTALL_PATH localiza los encabezados instalados de raylib y los archivos fuente asociados.
RAYLIB_H_INSTALL_PATH ?= $(DESTDIR)/include

# Tipo de biblioteca usada para raylib: STATIC (.a) o SHARED (.so/.dll)
RAYLIB_LIBTYPE        ?= STATIC

# Modo de compilación para el proyecto: DEBUG o RELEASE
BUILD_MODE            ?= RELEASE

# Usar la biblioteca GLFW externa en lugar del módulo rglfw
# TODO: Revisar el uso en Linux. Versión objetivo elegida. Activar con -lglfw o -lglfw3
USE_EXTERNAL_GLFW     ?= FALSE

# Usar el protocolo del servidor de pantalla Wayland en Linux
# por defecto se usa el sistema de ventanas X11
USE_WAYLAND_DISPLAY   ?= FALSE

# Determinar PLATFORM_OS en caso de que se seleccione PLATFORM_DESKTOP
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    # ¡No hay uname.exe en MinGW!, pero OS=Windows_NT en Windows
    # ifeq ($(UNAME),Msys) -> Windows
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS=WINDOWS
        export PATH := $(COMPILER_PATH):$(PATH)
    else
        UNAMEOS=$(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS=LINUX
        endif
        ifeq ($(UNAMEOS),FreeBSD)
            PLATFORM_OS=BSD
        endif
        ifeq ($(UNAMEOS),OpenBSD)
            PLATFORM_OS=BSD
        endif
        ifeq ($(UNAMEOS),NetBSD)
            PLATFORM_OS=BSD
        endif
        ifeq ($(UNAMEOS),DragonFly)
            PLATFORM_OS=BSD
        endif
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS=OSX
        endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    UNAMEOS=$(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS=LINUX
    endif
endif

# Ajuste de RAYLIB_PATH para diferentes plataformas.
# Si usas GNU make, podemos obtener la ruta completa al directorio principal. ¿Windows? ¿BSD?
# Requerido para ldconfig u otras herramientas que no realizan la expansión de rutas.
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
        RAYLIB_PREFIX ?= ..
        RAYLIB_PATH    = $(realpath $(RAYLIB_PREFIX))
    endif
endif
# Ruta predeterminada para raylib en Raspberry Pi, si se instala en un camino diferente, ¡actualízalo!
# Esto no se usa actualmente en src/Makefile. No estoy seguro de su origen o uso. Consulta la wiki.
# TODO: actualizar la meta install: en src/Makefile para RPI, considerar relación con LINUX.
ifeq ($(PLATFORM),PLATFORM_RPI)
    RAYLIB_PATH       ?= /home/pi/raylib
endif

ifeq ($(PLATFORM),PLATFORM_WEB)
    # Variables requeridas por Emscripten
    EMSDK_PATH          ?= C:/emsdk
    EMSCRIPTEN_VERSION  ?= 1.38.31
    CLANG_VERSION       = e$(EMSCRIPTEN_VERSION)_64bit
    PYTHON_VERSION      = 2.7.13.1_64bit\python-2.7.13.amd64
    NODE_VERSION        = 8.9.1_64bit
    export PATH         = $(EMSDK_PATH);$(EMSDK_PATH)\clang\$(CLANG_VERSION);$(EMSDK_PATH)\node\$(NODE_VERSION)\bin;$(EMSDK_PATH)\python\$(PYTHON_VERSION);$(EMSDK_PATH)\emscripten\$(EMSCRIPTEN_VERSION);C:\raylib\MinGW\bin:$$(PATH)
    EMSCRIPTEN          = $(EMSDK_PATH)\emscripten\$(EMSCRIPTEN_VERSION)
endif

# Definir el directorio de lanzamiento de raylib para la biblioteca compilada.
# RAYLIB_RELEASE_PATH apunta a binarios proporcionados o a tu versión recién compilada.
RAYLIB_RELEASE_PATH 	?= $(RAYLIB_PATH)/src

# EXAMPLE_RUNTIME_PATH incrusta una ubicación personalizada en tiempo de ejecución de libraylib.so u otras bibliotecas deseadas
# en cada binario de ejemplo compilado con RAYLIB_LIBTYPE=SHARED. Por defecto apunta a RAYLIB_RELEASE_PATH
# para que estos ejemplos se vinculen en tiempo de ejecución con tu versión de libraylib.so en ../release/libs/linux
# sin una instalación formal desde ../src/Makefile. Es útil para portabilidad y si tienes
# múltiples versiones de raylib, raylib instalado en una ubicación no estándar, o si quieres
# empaquetar libraylib.so con tu juego. Cámbialo según tu preferencia.
# NOTA: Si en tiempo de ejecución hay un libraylib.so tanto en EXAMPLE_RUNTIME_PATH como en RAYLIB_INSTALL_PATH,
# La biblioteca en EXAMPLE_RUNTIME_PATH, si está presente, tendrá prioridad sobre la de RAYLIB_INSTALL_PATH.
# Implementado para LINUX a continuación con CFLAGS += -Wl,-rpath,$(EXAMPLE_RUNTIME_PATH)
# Para ver el resultado, ejecuta readelf -d core/core_basic_window; buscando el atributo RPATH o RUNPATH.
# Para ver a qué bibliotecas se está vinculando un ejemplo compilado, ejecuta ldd core/core_basic_window;
# Busca libraylib.so.1 => $(RAYLIB_INSTALL_PATH)/libraylib.so.1 o listado similar.
EXAMPLE_RUNTIME_PATH   ?= $(RAYLIB_RELEASE_PATH)

# Define el compilador C predeterminado: gcc
# NOTA: define el compilador g++ si usas C++
CC = g++

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),OSX)
        # Compilador predeterminado en OSX
        CC = clang++
    endif
    ifeq ($(PLATFORM_OS),BSD)
        # Compilador predeterminado en FreeBSD, OpenBSD, NetBSD, DragonFly
        CC = clang
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    ifeq ($(USE_RPI_CROSS_COMPILER),TRUE)
        # Define el compilador cruzado para RPI
        #CC = armv6j-hardfloat-linux-gnueabi-gcc
        CC = $(RPI_TOOLCHAIN)/bin/arm-linux-gnueabihf-gcc
    endif
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    # Compilador de HTML5 para emscripten
    # ADVERTENCIA: Para compilar a HTML5, el código debe ser rediseñado
    # para usar emscripten.h y emscripten_set_main_loop()
    CC = emcc
endif

# Define el programa make predeterminado: Mingw32-make
MAKE = mingw32-make

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
        MAKE = make
    endif
    ifeq ($(PLATFORM_OS),OSX)
        MAKE = make
    endif
endif

# Define las banderas del compilador:
#  -O0                  define el nivel de optimización (sin optimización, mejor para depurar)
#  -O1                  define el nivel de optimización
#  -g                   incluye información de depuración en la compilación
#  -s                   elimina datos innecesarios de la compilación -> no usar en compilaciones de depuración
#  -Wall                habilita la mayoría, pero no todos, los warnings del compilador
#  -std=c99             define el modo del lenguaje C (C estándar de la revisión de 1999)
#  -std=gnu99           define el modo del lenguaje C (GNU C de la revisión de 1999)
#  -Wno-missing-braces  ignora warnings inválidos (error de GCC 53119)
#  -D_DEFAULT_SOURCE    usar con -std=c99 en Linux y PLATFORM_WEB, necesario para timespec
CFLAGS += -Wall -std=c++14 -D_DEFAULT_SOURCE -Wno-missing-braces

ifeq ($(BUILD_MODE),DEBUG)
    CFLAGS += -g -O0
else
    CFLAGS += -s -O1
endif

# Banderas adicionales para el compilador (si se desean)
#CFLAGS += -Wextra -Wmissing-prototypes -Wstrict-prototypes
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        # El archivo de recursos contiene el icono del ejecutable de Windows y propiedades
        # -Wl,--subsystem,windows oculta la ventana de la consola
        CFLAGS += $(RAYLIB_PATH)/src/raylib.rc.data
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        ifeq ($(RAYLIB_LIBTYPE),STATIC)
            CFLAGS += -D_DEFAULT_SOURCE
        endif
        ifeq ($(RAYLIB_LIBTYPE),SHARED)
            # Habilita explícitamente el enlace en tiempo de ejecución a libraylib.so
            CFLAGS += -Wl,-rpath,$(EXAMPLE_RUNTIME_PATH)
        endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    CFLAGS += -std=gnu99
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    # -Os                        # optimización de tamaño
    # -O2                        # nivel de optimización 2, si se usa, también se debe establecer --memory-init-file 0
    # -s USE_GLFW=3              # Usar la biblioteca glfw3 (gestión de contexto/entrada)
    # -s ALLOW_MEMORY_GROWTH=1   # para permitir el redimensionamiento de la memoria -> ADVERTENCIA: ¡Los buffers de audio podrían FALLAR!
    # -s TOTAL_MEMORY=16777216   # para especificar el tamaño de la memoria heap (por defecto = 16MB)
    # -s USE_PTHREADS=1          # soporte para multihilos
    # -s WASM=0                  # deshabilita Web Assembly, emitido por defecto
    # -s EMTERPRETIFY=1          # habilita el intérprete de código de emscripten (muy lento)
    # -s EMTERPRETIFY_ASYNC=1    # soporta bucles síncronos por el emterpreter
    # -s FORCE_FILESYSTEM=1      # fuerza a que el sistema de archivos cargue/guarde datos de archivos
    # -s ASSERTIONS=1            # habilita verificaciones en tiempo de ejecución para errores comunes en la asignación de memoria (-O1 y por encima lo apagan)
    # --profiling                # incluye información para el perfilado del código
    # --memory-init-file 0       # para evitar un archivo externo de inicialización de memoria (.mem)
    # --preload-file resources   # especifica una carpeta de recursos para la compilación de datos
    CFLAGS += -Os -s USE_GLFW=3 -s TOTAL_MEMORY=16777216 --preload-file resources
    ifeq ($(BUILD_MODE), DEBUG)
        CFLAGS += -s ASSERTIONS=1 --profiling
    endif

    # Define un archivo HTML y extensión de salida personalizados
    CFLAGS += --shell-file $(RAYLIB_PATH)/src/shell.html
    EXT = .html
endif

# Define las rutas de inclusión para los encabezados necesarios
# NOTA: Varias bibliotecas externas requeridas (stb y otras)
INCLUDE_PATHS = -I. -I$(RAYLIB_PATH)/src -I$(RAYLIB_PATH)/src/external
ifneq ($(wildcard /opt/homebrew/include/.*),)
    INCLUDE_PATHS += -I/opt/homebrew/include
endif

# Define directorios adicionales que contienen los encabezados requeridos
ifeq ($(PLATFORM),PLATFORM_RPI)
    # Bibliotecas requeridas en RPI
    INCLUDE_PATHS += -I/opt/vc/include
    INCLUDE_PATHS += -I/opt/vc/include/interface/vmcs_host/linux
    INCLUDE_PATHS += -I/opt/vc/include/interface/vcos/pthreads
endif
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),BSD)
        # Considerar -L$(RAYLIB_H_INSTALL_PATH)
        INCLUDE_PATHS += -I/usr/local/include
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        # Restablecer todo.
        # Precedencia: local inmediato, versión instalada, bibliotecas proporcionadas por raysan5 -I$(RAYLIB_H_INSTALL_PATH) -I$(RAYLIB_PATH)/release/include
        INCLUDE_PATHS = -I$(RAYLIB_H_INSTALL_PATH) -isystem. -isystem$(RAYLIB_PATH)/src -isystem$(RAYLIB_PATH)/release/include -isystem$(RAYLIB_PATH)/src/external
    endif
endif

# Define las rutas de las bibliotecas que contienen las bibliotecas requeridas.
LDFLAGS = -L.

ifneq ($(wildcard $(RAYLIB_RELEASE_PATH)/.*),)
    LDFLAGS += -L$(RAYLIB_RELEASE_PATH)
endif
ifneq ($(wildcard $(RAYLIB_PATH)/src/.*),)
    LDFLAGS += -L$(RAYLIB_PATH)/src
endif
ifneq ($(wildcard /opt/homebrew/lib/.*),)
    LDFLAGS += -L/opt/homebrew/lib
endif

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),BSD)
        # Considerar -L$(RAYLIB_INSTALL_PATH)
        LDFLAGS += -L. -Lsrc -L/usr/local/lib
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        # Restablecer todo.
        # Precedencia: local inmediato, versión instalada, bibliotecas proporcionadas por raysan5
        LDFLAGS = -L. -L$(RAYLIB_INSTALL_PATH) -L$(RAYLIB_RELEASE_PATH)
    endif
endif

ifeq ($(PLATFORM),PLATFORM_RPI)
    LDFLAGS += -L/opt/vc/lib
endif

# Define las bibliotecas requeridas en el enlace
# si deseas vincular bibliotecas (libname.so o libname.a), usa -lname
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        # Bibliotecas para la compilación en escritorio en Windows
        # NOTA: La biblioteca WinMM es requerida para establecer la resolución del temporizador de alta precisión
        LDLIBS = -lraylib -lopengl32 -lgdi32 -lwinmm
        # Requerido para los ejemplos de physac
        #LDLIBS += -static -lpthread
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        # Bibliotecas para la compilación en escritorio Debian GNU/Linux
        # NOTA: Paquetes requeridos: libegl1-mesa-dev
        LDLIBS = -lraylib -lGL -lm -lpthread -ldl -lrt
        
        # En X11 también requiere las siguientes bibliotecas
        LDLIBS += -lX11
        # NOTA: Parece que las bibliotecas adicionales ya no son necesarias, la última versión de GLFW las carga automáticamente
        #LDLIBS += -lXrandr -lXinerama -lXi -lXxf86vm -lXcursor
        
        # En el sistema de ventanas Wayland, se requieren bibliotecas adicionales
        ifeq ($(USE_WAYLAND_DISPLAY),TRUE)
            LDLIBS += -lwayland-client -lwayland-cursor -lwayland-egl -lxkbcommon
        endif
        # Enlace explícito a libc
        ifeq ($(RAYLIB_LIBTYPE),SHARED)
            LDLIBS += -lc
        endif
    endif
    ifeq ($(PLATFORM_OS),OSX)
        # Bibliotecas para la compilación en escritorio en OSX 10.9
        # NOTA: Paquetes requeridos: libopenal-dev libegl1-mesa-dev
        LDLIBS = -lraylib -framework OpenGL -framework OpenAL -framework Cocoa -framework IOKit
    endif
    ifeq ($(PLATFORM_OS),BSD)
        # Bibliotecas para la compilación en escritorio en FreeBSD, OpenBSD, NetBSD, DragonFly
        # NOTA: Paquetes requeridos: mesa-libs
        LDLIBS = -lraylib -lGL -lpthread -lm

        # En XWindow también requiere las siguientes bibliotecas
        LDLIBS += -lX11 -lXrandr -lXinerama -lXi -lXxf86vm -lXcursor
    endif
    ifeq ($(USE_EXTERNAL_GLFW),TRUE)
        # NOTA: Podría requerir paquetes adicionales instalados: libglfw3-dev
        LDLIBS += -lglfw
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    # Bibliotecas para la compilación en Raspberry Pi
    # NOTA: Paquetes requeridos: libasound2-dev (ALSA)
    LDLIBS = -lraylib -lbrcmGLESv2 -lbrcmEGL -lpthread -lrt -lm -lbcm_host -ldl
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    # Bibliotecas para la compilación web (HTML5)
    LDLIBS = $(RAYLIB_RELEASE_PATH)/libraylib.bc
endif

# Define una función recursiva para los comodines
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

# Define todos los archivos fuente requeridos
SRC_DIR = src
OBJ_DIR = obj

# Define todos los archivos objeto a partir de los archivos fuente
SRC = $(call rwildcard, *.c, *.h)
#OBJS = $(SRC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
OBJS ?= main.c

# Para la plataforma Android, llamamos a un Makefile personalizado Makefile.Android
ifeq ($(PLATFORM),PLATFORM_ANDROID)
    MAKEFILE_PARAMS = -f Makefile.Android 
    export PROJECT_NAME
    export SRC_DIR
else
    MAKEFILE_PARAMS = $(PROJECT_NAME)
endif

# Entrada por defecto del objetivo
# NOTA: Llamamos a este objetivo del Makefile o al objetivo de Makefile.Android
all:
	$(MAKE) $(MAKEFILE_PARAMS)

# Objetivo del proyecto definido por PROJECT_NAME
$(PROJECT_NAME): $(OBJS)
	$(CC) -o $(PROJECT_NAME)$(EXT) $(OBJS) $(CFLAGS) $(INCLUDE_PATHS) $(LDFLAGS) $(LDLIBS) -D$(PLATFORM)

# Compilar archivos fuente
# NOTA: Este patrón compilará todos los módulos definidos en $(OBJS)
#%.o: %.c
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) -c $< -o $@ $(CFLAGS) $(INCLUDE_PATHS) -D$(PLATFORM)

# Limpiar todo
clean:
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
		del *.o *.exe /s
    endif
    ifeq ($(PLATFORM_OS),LINUX)
	find -type f -executable | xargs file -i | grep -E 'x-object|x-archive|x-sharedlib|x-executable' | rev | cut -d ':' -f 2- | rev | xargs rm -fv
    endif
    ifeq ($(PLATFORM_OS),OSX)
		find . -type f -perm +ugo+x -delete
		rm -f *.o
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
	find . -type f -executable -delete
	rm -fv *.o
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
	del *.o *.html *.js
endif
	@echo Cleaning done

