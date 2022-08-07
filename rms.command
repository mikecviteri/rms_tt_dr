#!/usr/local/bin/python3

import os
import subprocess
from pydub import AudioSegment
import shutil
from tqdm import tqdm

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def main():
  working_dir = input("Ingresa la carpeta con los audios")
  folder = create_folder()
  f = open(f'{working_dir.strip()}/{os.path.basename(working_dir.strip())}_dr.txt', 'w')
  separator(f)
  f.write('Analyzed folder: {}\n'.format(working_dir))
  separator(f, '-')
  f.write("{: <20} {: <20} {: <20}\n".format('Peak', 'RMS', 'Filename'))
  separator(f)
  snd_files = [i for i in os.listdir(working_dir) if i.endswith('.wav') or i.endswith('.mp3')]

  peaks = []
  rms = []
  audiofiles = []

  for snd_file in tqdm(snd_files):
    snd_file_handle = os.path.join(working_dir, snd_file)
    channels = AudioSegment.from_file(file=snd_file_handle, format=os.path.splitext(snd_file_handle)[1][1:]).channels
    snd_stats = get_sox_stats_on_file(snd_file_handle) if snd_file.endswith('.wav') else get_sox_stats_on_file(convert_to_wav(folder, snd_file_handle))
    peak = float(snd_stats[3 if channels == 1 else 4].split(' ')[-1])
    full_peak = str('{:.2f}'.format(peak)) + ' dB' if peak else 'over'
    peaks.append(full_peak)
    level = '{:.2f}'.format(float(snd_stats[4 if channels == 1 else 5].split(' ')[-1]) + 3.0) + ' dB'
    rms.append(level)
    audiofiles.append(snd_file)
    f.write("{: <20} {: <20} {: <20}\n".format(full_peak, level, snd_file))
  remove_folder(folder)
  separator(f)
  f.write('\nNumber of files:\t{}\n\n'.format(len(snd_files)))
  separator(f, '=')

  lines = []
  color = []

  for i in range(len(audiofiles)):
    if peaks[i].split()[0] == 'over' or peaks[i].split()[0] == '-inf':
      color.append(bcolors.FAIL)
      lines.append('Ajusta el {} de este audio'.format('peak' if peaks[i].split()[0] == 'over' else 'silencio') + bcolors.ENDC)
    elif rms[i].split()[0] == '-inf':
      color.append(bcolors.FAIL)
      lines.append('Este audio es silencio' + bcolors.ENDC)
    elif min(22.9, 23.5) < float(rms[i].split()[0]) * -1 < max(22.9, 23.5):
      color.append(bcolors.OKGREEN)
      lines.append('Audio OK!' + bcolors.ENDC)
    else:
      color.append(bcolors.FAIL)
      diff = round(float(23) + float(rms[i].split()[0]), 2) * -1
      result = '+' if diff > 0 else '-'
      lines.append(' Ajusta el nivel a {}'.format(result + str(diff)) + bcolors.ENDC)

  for i in range(len(audiofiles)):
    print("{} {: <20} {: <20} {: <60} {: <20}".format(color[i], peaks[i], rms[i], audiofiles[i], lines[i]))

def separator(file, sep='-'):
  file.write(sep * 94)
  file.write('\n')

def create_folder():
  dir = os.path.expanduser("~/Desktop")
  temp_folder = '.temp_wavs'
  folder = os.path.join(dir, temp_folder)
  if os.path.isdir(folder):
    for f in os.listdir(folder):
      os.remove(os.path.join(folder, f))
  else:
    os.makedirs(folder)
  return folder

def remove_folder(path):
  shutil.rmtree(path)

def get_sox_stats_on_file(file_handle):
  sox_call = subprocess.Popen(["sox", file_handle, "-n", "stats"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  stdout, stderr = sox_call.communicate()
  file_stats_one_line = (stderr.decode("utf-8"))
  file_stats = (file_stats_one_line.splitlines())
  return file_stats

def convert_to_wav(path, input_file):
  audSeg = AudioSegment.from_mp3(input_file)
  wavFile = os.path.join(path, os.path.basename(os.path.normpath(input_file))[:-4] + '.wav')
  audSeg.export(wavFile, format="wav")
  return wavFile

if __name__ == "__main__":
  main()