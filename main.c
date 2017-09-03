/*
 * Copyright (c) 2015 Andrew Kelley
 *
 * This file is part of libsoundio, which is MIT licensed.
 * See http://opensource.org/licenses/MIT
 */


#include <soundio/soundio.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#include "main.h"


// haskell test
#include <HsFFI.h>
#ifdef __GLASGOW_HASKELL__
#include "Hcli_stub.h"
extern void __stginit_Hcli(void);
#endif


static int usage(char *exe) {
    fprintf(stderr, "Usage: %s [options]\n"
            "Options:\n"
            "  [--backend dummy|alsa|pulseaudio|jack|coreaudio|wasapi]\n"
            "  [--device id]\n"
            "  [--raw]\n"
            "  [--name stream_name]\n"
            "  [--latency seconds]\n"
            "  [--sample-rate hz]\n"
            , exe);
    return 1;
}

static void write_sample_s16ne(char *ptr, double sample) {
    int16_t *buf = (int16_t *)ptr;
    double range = (double)INT16_MAX - (double)INT16_MIN;
    double val = sample * range / 2.0;
    *buf = val;
}

static void write_sample_s32ne(char *ptr, double sample) {
    int32_t *buf = (int32_t *)ptr;
    double range = (double)INT32_MAX - (double)INT32_MIN;
    double val = sample * range / 2.0;
    *buf = val;
}

static void write_sample_float32ne(char *ptr, double sample) {
    float *buf = (float *)ptr;
    *buf = sample;
}

static void write_sample_float64ne(char *ptr, double sample) {
    double *buf = (double *)ptr;
    *buf = sample;
}

static void (*write_sample)(char *ptr, double sample);
static const double PI = 3.14159265358979323846264338328;
static double seconds_offset = 0.0;
static volatile bool want_pause = false;
static void write_callback(struct SoundIoOutStream *outstream, int frame_count_min, int frame_count_max) {
    double float_sample_rate = outstream->sample_rate;
    double seconds_per_frame = 1.0 / float_sample_rate;
    struct SoundIoChannelArea *areas;
    int err;
    int frames_left = frame_count_max;

    for (;;) {
        int frame_count = frames_left;
        if ((err = soundio_outstream_begin_write(outstream, &areas, &frame_count))) {
            fprintf(stderr, "unrecoverable stream error: %s\n", soundio_strerror(err));
            exit(1);
        }

        if (!frame_count)
            break;

        const struct SoundIoChannelLayout *layout = &outstream->layout;

        double pitch = 440.0;
        double radians_per_second = pitch * 2.0 * PI;
#ifdef SINGLE_SAMPLE /* sample-by-sample */
        for (int frame=0; frame < frame_count; frame++){
            for (int channel=0; channel<layout->channel_count; channel++){
                float in;
                float out;
                module_process_frame( &in, &out, 1 );
                write_sample( areas[channel].ptr, out );
                areas[channel].ptr += areas[channel].step;

            }
        }
#else /* block process  */
        // nb: these should be doubles for desktop applications
        // assuming a single channel rn
        float in[frame_count];
        float out[frame_count];
        // read_sample into the in[] buffer

        module_process_frame( in, out, frame_count );

        // nb: need to wrap channels here as well
        for( int frame=0; frame < frame_count; frame++ ){
            for(int channel=0; channel<layout->channel_count; channel++){
                write_sample( areas[channel].ptr, out[frame] );
                areas[channel].ptr += areas[channel].step;
            }
        }

#endif /* end sample process */

        seconds_offset = fmod(seconds_offset + seconds_per_frame * frame_count, 1.0);

        if ((err = soundio_outstream_end_write(outstream))) {
            if (err == SoundIoErrorUnderflow)
                return;
            fprintf(stderr, "unrecoverable stream error: %s\n", soundio_strerror(err));
            exit(1);
        }

        frames_left -= frame_count;
        if (frames_left <= 0)
            break;
    }

    soundio_outstream_pause(outstream, want_pause);
}

static void underflow_callback(struct SoundIoOutStream *outstream) {
    static int count = 0;
    fprintf(stderr, "underflow %d\n", count++);
}

int main(int argc, char **argv) {
    char *exe = argv[0];
    enum SoundIoBackend backend = SoundIoBackendNone;
    char *device_id = NULL;
    bool raw = false;
    char *stream_name = NULL;
    double latency = 0.0;
    int sample_rate = 0;


    for (int i = 1; i < argc; i += 1) {
        char *arg = argv[i];
        if (arg[0] == '-' && arg[1] == '-') {
            if (strcmp(arg, "--raw") == 0) {
                raw = true;
            } else {
                i += 1;
                if (i >= argc) {
                    return usage(exe);
                } else if (strcmp(arg, "--backend") == 0) {
                    if (strcmp(argv[i], "dummy") == 0) {
                        backend = SoundIoBackendDummy;
                    } else if (strcmp(argv[i], "alsa") == 0) {
                        backend = SoundIoBackendAlsa;
                    } else if (strcmp(argv[i], "pulseaudio") == 0) {
                        backend = SoundIoBackendPulseAudio;
                    } else if (strcmp(argv[i], "jack") == 0) {
                        backend = SoundIoBackendJack;
                    } else if (strcmp(argv[i], "coreaudio") == 0) {
                        backend = SoundIoBackendCoreAudio;
                    } else if (strcmp(argv[i], "wasapi") == 0) {
                        backend = SoundIoBackendWasapi;
                    } else {
                        fprintf(stderr, "Invalid backend: %s\n", argv[i]);
                        return 1;
                    }
                } else if (strcmp(arg, "--device") == 0) {
                    device_id = argv[i];
                } else if (strcmp(arg, "--name") == 0) {
                    stream_name = argv[i];
                } else if (strcmp(arg, "--latency") == 0) {
                    latency = atof(argv[i]);
                } else if (strcmp(arg, "--sample-rate") == 0) {
                    sample_rate = atoi(argv[i]);
                } else {
                    return usage(exe);
                }
            }
        } else {
            return usage(exe);
        }
    }

    struct SoundIo *soundio = soundio_create();
    if (!soundio) {
        fprintf(stderr, "out of memory\n");
        return 1;
    }

    int err = (backend == SoundIoBackendNone) ?
        soundio_connect(soundio) : soundio_connect_backend(soundio, backend);

    if (err) {
        fprintf(stderr, "Unable to connect to backend: %s\n", soundio_strerror(err));
        return 1;
    }

    fprintf(stderr, "Backend: %s\n", soundio_backend_name(soundio->current_backend));

    soundio_flush_events(soundio);

    int selected_device_index = -1;
    if (device_id) {
        int device_count = soundio_output_device_count(soundio);
        for (int i = 0; i < device_count; i += 1) {
            struct SoundIoDevice *device = soundio_get_output_device(soundio, i);
            bool select_this_one = strcmp(device->id, device_id) == 0 && device->is_raw == raw;
            soundio_device_unref(device);
            if (select_this_one) {
                selected_device_index = i;
                break;
            }
        }
    } else {
        selected_device_index = soundio_default_output_device_index(soundio);
    }

    if (selected_device_index < 0) {
        fprintf(stderr, "Output device not found\n");
        return 1;
    }

    struct SoundIoDevice *device = soundio_get_output_device(soundio, selected_device_index);
    if (!device) {
        fprintf(stderr, "out of memory\n");
        return 1;
    }

    fprintf(stderr, "Output device: %s\n", device->name);

    if (device->probe_error) {
        fprintf(stderr, "Cannot probe device: %s\n", soundio_strerror(device->probe_error));
        return 1;
    }

    struct SoundIoOutStream *outstream = soundio_outstream_create(device);
    if (!outstream) {
        fprintf(stderr, "out of memory\n");
        return 1;
    }

    outstream->write_callback = write_callback;
    outstream->underflow_callback = underflow_callback;
    outstream->name = stream_name;
    outstream->software_latency = latency;
    outstream->sample_rate = sample_rate;

    if (soundio_device_supports_format(device, SoundIoFormatFloat32NE)) {
        outstream->format = SoundIoFormatFloat32NE;
        write_sample = write_sample_float32ne;
    } else if (soundio_device_supports_format(device, SoundIoFormatFloat64NE)) {
        outstream->format = SoundIoFormatFloat64NE;
        write_sample = write_sample_float64ne;
    } else if (soundio_device_supports_format(device, SoundIoFormatS32NE)) {
        outstream->format = SoundIoFormatS32NE;
        write_sample = write_sample_s32ne;
    } else if (soundio_device_supports_format(device, SoundIoFormatS16NE)) {
        outstream->format = SoundIoFormatS16NE;
        write_sample = write_sample_s16ne;
    } else {
        fprintf(stderr, "No suitable device format available.\n");
        return 1;
    }

    // create structures / objects for child process
    module_init();

    if ((err = soundio_outstream_open(outstream))) {
        fprintf(stderr, "unable to open device: %s", soundio_strerror(err));
        return 1;
    }

    fprintf(stderr, "Software latency: %f\n", outstream->software_latency);
    fprintf(stderr,
            "'.s'   - print graph layout\n"
            "'get'  - print the value of named param\n"
            "'set'  - set the value of named param\n"
            "':q'   - quit\n");

    if (outstream->layout_error)
        fprintf(stderr, "unable to set channel layout: %s\n", soundio_strerror(outstream->layout_error));

    if ((err = soundio_outstream_start(outstream))) {
        fprintf(stderr, "unable to start device: %s\n", soundio_strerror(err));
        return 1;
    }




    for (;;) {
        soundio_flush_events(soundio);

/*
        char cli_stdin[256];
        char cli_response[256];
        // clear the buffers each loop
        memset( cli_stdin, 0, 256 );
        memset( cli_response, 0, 256 );

        // should update fgets() to getline() for handling of NULLs
        fprintf( stderr
               , "%s\n"
               , module_cli( fgets ( cli_stdin
                                   , 256
                                   , stdin
                                   )
                           , cli_response
                           )
               );
        const char* cli_quit  = ":q";
        const char  cli_q_len = strlen(cli_quit);
        if( 0 == memcmp( cli_stdin
                       , cli_quit
                       , cli_q_len ) ){
            break;
        }
*/

break;
   }


    hs_init(&argc, &argv);
#ifdef __GLASGOW_HASKELL__
    hs_add_root(__stginit_Hcli);
#endif

// after hs is init we should run the first part of intepreter
// this just inits the state w dictionary.
//
// that function returns IO () (FunPtr (IO))
// which is a fnptr that can be used to call back into haskell
//
// thus at start of for() loop we run interpreter
// it returns fnptr to it's continuation
// then we iterate with printf outside
//
// how to get the interpretted info out of haskell though if we're returning fnptr?
// can use a IO() fn to access the outside world?
//
//
// if all of this fails, we just don't maintain state inside of haskell.
// we just use it as a helpful interpreter with pattern matching
// which can format our commands for us
// basically it will return easily parsed fn pointers & arguments
// preferably in some generic wrapper so parsing in C is super simple
//
// try and get interop working, so haskell can query (in c) address of structs
// and perhaps even trigger the CLI fns directly
//
//
// see: https://www.haskell.org/onlinereport/haskell2010/haskellch8.html#x15-1490008
// particularly 'Dynamic Wrapper' 2/3rds down the page

    cli_hs();
    hs_exit(); // end haskell stub

    fprintf( stderr
           , "leaving..\n"
           );

    soundio_outstream_destroy(outstream);
    soundio_device_unref(device);
    soundio_destroy(soundio);
    return 0;
}
