package dev.bunbu.bunbu

data class BunbuPreset(
    val label: String,
    val code: String
)

val bunbuPresets = listOf(
    BunbuPreset(
        label = "Todo List",
        code = """
import React, { useState } from 'react';
import { View, Text, TouchableOpacity, FlatList, StyleSheet } from 'react-native';

const tasks = ['Buy groceries', 'Walk the dog', 'Read a book', 'Write React Native code', 'Go to the gym'];

export default function Main() {
  const [done, setDone] = useState(new Set());
  const toggle = (i) => {
    const next = new Set(done);
    next.has(i) ? next.delete(i) : next.add(i);
    setDone(next);
  };
  return (
    <View style={s.root}>
      <View style={s.header}><Text style={s.title}>My Tasks</Text></View>
      <FlatList
        data={tasks}
        keyExtractor={(_, i) => String(i)}
        renderItem={({ item, index }) => (
          <TouchableOpacity style={s.row} onPress={() => toggle(index)}>
            <Text style={s.icon}>{done.has(index) ? '✅' : '⬜'}</Text>
            <Text style={[s.label, done.has(index) && s.struck]}>{item}</Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1A1A2E' },
  header: { padding: 16, backgroundColor: '#6C63FF' },
  title: { fontSize: 20, fontWeight: '700', color: '#fff' },
  row: { flexDirection: 'row', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: '#2A2A3E' },
  icon: { fontSize: 20, marginRight: 12 },
  label: { fontSize: 16, color: '#E0E0E0' },
  struck: { textDecorationLine: 'line-through', color: '#666666' },
});
""".trimIndent()
    ),
    BunbuPreset(
        label = "Profile",
        code = """
import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';

export default function Main() {
  return (
    <ScrollView style={s.root}>
      <View style={s.header}>
        <View style={s.avatar}><Text style={s.initials}>JD</Text></View>
        <Text style={s.name}>Jane Doe</Text>
        <Text style={s.sub}>React Native Developer</Text>
      </View>
      <View style={s.stats}>
        {[['142','Posts'],['1.2k','Followers'],['89','Following']].map(([n,l])=>(
          <View key={l} style={s.stat}><Text style={s.statN}>{n}</Text><Text style={s.statL}>{l}</Text></View>
        ))}
      </View>
      <View style={s.info}>
        <Text style={s.infoRow}>📧  jane.doe@email.com</Text>
        <Text style={s.infoRow}>📍  San Francisco, CA</Text>
        <Text style={s.infoRow}>🔗  github.com/janedoe</Text>
      </View>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1A1A2E' },
  header: { alignItems: 'center', paddingVertical: 32, backgroundColor: '#2196F3' },
  avatar: { width: 100, height: 100, borderRadius: 50, backgroundColor: '#1976D2', justifyContent: 'center', alignItems: 'center' },
  initials: { fontSize: 36, color: '#fff', fontWeight: '700' },
  name: { fontSize: 24, fontWeight: '700', color: '#fff', marginTop: 12 },
  sub: { fontSize: 16, color: '#B3E5FC', marginTop: 4 },
  stats: { flexDirection: 'row', justifyContent: 'space-evenly', paddingVertical: 24 },
  stat: { alignItems: 'center' },
  statN: { fontSize: 20, fontWeight: '700', color: '#E0E0E0' },
  statL: { fontSize: 14, color: '#888888' },
  info: { padding: 24 },
  infoRow: { fontSize: 16, paddingVertical: 8, color: '#E0E0E0' },
});
""".trimIndent()
    ),
    BunbuPreset(
        label = "Weather",
        code = """
import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';

const days = [
  { day: 'Mon', icon: '☀️', temp: 74 },
  { day: 'Tue', icon: '☁️', temp: 68 },
  { day: 'Wed', icon: '☁️', temp: 65 },
  { day: 'Thu', icon: '☀️', temp: 71 },
  { day: 'Fri', icon: '☀️', temp: 75 },
];

export default function Main() {
  return (
    <ScrollView style={s.root} contentContainerStyle={s.content}>
      <Text style={s.icon}>☀️</Text>
      <Text style={s.city}>San Francisco</Text>
      <Text style={s.temp}>72°F</Text>
      <Text style={s.desc}>Sunny</Text>
      <View style={s.details}>
        {[['💧','45%','Humidity'],['💨','12 mph','Wind'],['👁','10 mi','Visibility']].map(([i,v,l])=>(
          <View key={l} style={s.detail}><Text style={s.dIcon}>{i}</Text><Text style={s.dVal}>{v}</Text><Text style={s.dLbl}>{l}</Text></View>
        ))}
      </View>
      <View style={s.forecast}>
        {days.map(d => (
          <View key={d.day} style={s.fDay}>
            <Text style={s.fLabel}>{d.day}</Text>
            <Text style={s.fIcon}>{d.icon}</Text>
            <Text style={s.fTemp}>{d.temp}°</Text>
          </View>
        ))}
      </View>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1565C0' },
  content: { alignItems: 'center', paddingVertical: 40 },
  icon: { fontSize: 80 },
  city: { fontSize: 28, color: '#fff', marginTop: 16 },
  temp: { fontSize: 64, color: '#fff' },
  desc: { fontSize: 18, color: '#90CAF9' },
  details: { flexDirection: 'row', marginTop: 40, width: '80%', justifyContent: 'space-around' },
  detail: { alignItems: 'center' },
  dIcon: { fontSize: 24 },
  dVal: { color: '#fff', fontWeight: '700', marginTop: 4 },
  dLbl: { color: '#90CAF9', fontSize: 12 },
  forecast: { flexDirection: 'row', marginTop: 40, width: '90%', justifyContent: 'space-evenly' },
  fDay: { alignItems: 'center' },
  fLabel: { color: '#90CAF9' },
  fIcon: { fontSize: 28, marginVertical: 4 },
  fTemp: { color: '#fff' },
});
""".trimIndent()
    ),
)
