import React, { useEffect, useState } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  View,
  Text,
  Platform,
  StatusBar,
  TouchableOpacity,
} from 'react-native';
import { RTNGodot, RTNGodotView, runOnGodotThread } from '@borndotcom/react-native-godot';
import * as FileSystem from 'expo-file-system/legacy';

const App = () => {
  const [godotInitialized, setGodotInitialized] = useState(false);
  const [score, setScore] = useState(0);
  const [isPaused, setIsPaused] = useState(false);

  useEffect(() => {
    initGodot();
    return () => {
      destroyGodot();
    };
  }, []);

  const initGodot = () => {
    runOnGodotThread(() => {
      'worklet';
      console.log('Initializing Donkey GTA Game...');

      try {
        if (Platform.OS === 'android') {
          RTNGodot.createInstance([
            '--verbose',
            '--path',
            '/main',
            '--rendering-driver',
            'opengl3',
            '--rendering-method',
            'gl_compatibility',
            '--display-driver',
            'embedded',
          ]);
        } else {
          RTNGodot.createInstance([
            '--verbose',
            '--main-pack',
            FileSystem.bundleDirectory + 'main.pck',
            '--rendering-driver',
            'opengl3',
            '--rendering-method',
            'gl_compatibility',
            '--display-driver',
            'embedded',
          ]);
        }

        // Connect to Godot signals for score updates
        const Godot = RTNGodot.API();
        const engine = Godot.Engine;
        const sceneTree = engine.get_main_loop();
        const root = sceneTree.get_root();

        // Find the game manager node to connect signals
        const gameManager = root.find_child('GameManager', true, false);
        if (gameManager) {
          gameManager.score_changed.connect((newScore: number) => {
            setScore(newScore);
          });
        }

        setGodotInitialized(true);
        console.log('Donkey GTA initialized successfully!');
      } catch (error) {
        console.error('Failed to initialize Godot:', error);
      }
    });
  };

  const destroyGodot = () => {
    runOnGodotThread(() => {
      'worklet';
      RTNGodot.destroyInstance();
    });
  };

  const togglePause = () => {
    if (isPaused) {
      RTNGodot.resume();
    } else {
      RTNGodot.pause();
    }
    setIsPaused(!isPaused);
  };

  const restartGame = () => {
    destroyGodot();
    setScore(0);
    setTimeout(() => {
      initGodot();
    }, 100);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" />

      {/* Game View */}
      <RTNGodotView style={styles.gameView} />

      {/* UI Overlay */}
      <View style={styles.overlay}>
        <View style={styles.topBar}>
          <Text style={styles.title}>🫏 DONKEY GTA</Text>
          <Text style={styles.score}>Score: {score}</Text>
        </View>

        <View style={styles.controls}>
          <TouchableOpacity style={styles.button} onPress={togglePause}>
            <Text style={styles.buttonText}>{isPaused ? '▶️ Resume' : '⏸️ Pause'}</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={restartGame}>
            <Text style={styles.buttonText}>🔄 Restart</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.instructions}>
          <Text style={styles.instructionText}>🕹️ On-screen controls to move</Text>
          <Text style={styles.instructionText}>👊 Kick button to attack</Text>
          <Text style={styles.instructionText}>🎯 Kick pedestrians for points!</Text>
        </View>
      </View>

      {!godotInitialized && (
        <View style={styles.loading}>
          <Text style={styles.loadingText}>Loading Donkey GTA...</Text>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  gameView: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: 'box-none',
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFD700',
    textShadowColor: '#000',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  score: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFF',
    textShadowColor: '#000',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  controls: {
    position: 'absolute',
    top: 80,
    right: 16,
    gap: 8,
  },
  button: {
    backgroundColor: 'rgba(255, 215, 0, 0.8)',
    padding: 12,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#FFF',
    minWidth: 120,
  },
  buttonText: {
    color: '#000',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  instructions: {
    position: 'absolute',
    bottom: 16,
    left: 16,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#FFD700',
  },
  instructionText: {
    color: '#FFF',
    fontSize: 14,
    marginBottom: 4,
  },
  loading: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
  },
  loadingText: {
    fontSize: 24,
    color: '#FFD700',
    fontWeight: 'bold',
  },
});

export default App;
