export interface VoiceConfig {
  value: string;
  label: string;
  provider: 'vapi' | 'deepgram';
  gender: 'masculine' | 'feminine';
  audioUrl?: string;
  description?: string;
  useCase?: string;
}

// VAPI voices (existing voices)
export const vapiVoices: VoiceConfig[] = [
  { value: 'Elliot', label: 'Elliot (Male)', provider: 'vapi', gender: 'masculine'},
  { value: 'Rohan', label: 'Rohan (Male)', provider: 'vapi', gender: 'masculine' },
  { value: 'Savannah', label: 'Savannah (Female)', provider: 'vapi', gender: 'feminine' },
  { value: 'Leah', label: 'Leah (Female)', provider: 'vapi', gender: 'feminine' },
  { value: 'Tara', label: 'Tara (Female)', provider: 'vapi', gender: 'feminine' },
  { value: 'Jess', label: 'Jess (Female)', provider: 'vapi', gender: 'feminine' },
  { value: 'Leo', label: 'Leo (Male)', provider: 'vapi', gender: 'masculine' },
  { value: 'Dan', label: 'Dan (Male)', provider: 'vapi', gender: 'masculine' },
  { value: 'Mia', label: 'Mia (Female)', provider: 'vapi', gender: 'feminine' },
  { value: 'Zac', label: 'Zac (Male)', provider: 'vapi', gender: 'masculine' },
  { value: 'Zoe', label: 'Zoe (Female)', provider: 'vapi', gender: 'feminine' },
];

// Deepgram voices (from deepgram file)
export const deepgramVoices: VoiceConfig[] = [
  { value: 'amalthea', label: 'Amalthea (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-amalthea.wav', description: 'Engaging, Natural, Cheerful', useCase: 'Casual chat' },
  { value: 'apollo', label: 'Apollo (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-apollo.wav', description: 'Confident, Comfortable, Casual', useCase: 'Casual chat' },
  { value: 'arcas', label: 'Arcas (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-arcas.wav', description: 'Natural, Smooth, Clear, Comfortable', useCase: 'Customer service, casual chat' },
  { value: 'aries', label: 'Aries (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-aries.wav', description: 'Warm, Energetic, Caring', useCase: 'Casual chat' },
  { value: 'asteria', label: 'Asteria (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-asteria.wav', description: 'Clear, Confident, Knowledgeable, Energetic', useCase: 'Advertising' },
  { value: 'athena', label: 'Athena (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-athena.wav', description: 'Calm, Smooth, Professional', useCase: 'Storytelling' },
  { value: 'atlas', label: 'Atlas (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-atlas.wav', description: 'Enthusiastic, Confident, Approachable, Friendly', useCase: 'Advertising' },
  { value: 'aurora', label: 'Aurora (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-aurora.wav', description: 'Cheerful, Expressive, Energetic', useCase: 'Interview' },
  { value: 'callista', label: 'Callista (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-callista.wav', description: 'Clear, Energetic, Professional, Smooth', useCase: 'IVR' },
  { value: 'cora', label: 'Cora (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-cora.wav', description: 'Smooth, Melodic, Caring', useCase: 'Storytelling' },
  { value: 'cordelia', label: 'Cordelia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-cordelia.wav', description: 'Approachable, Warm, Polite', useCase: 'Storytelling' },
  { value: 'delia', label: 'Delia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-delia.wav', description: 'Casual, Friendly, Cheerful, Breathy', useCase: 'Interview' },
  { value: 'draco', label: 'Draco (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-draco.wav', description: 'Warm, Approachable, Trustworthy, Baritone', useCase: 'Storytelling' },
  { value: 'electra', label: 'Electra (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-electra.wav', description: 'Professional, Engaging, Knowledgeable', useCase: 'IVR, advertising, customer service' },
  { value: 'harmonia', label: 'Harmonia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-harmonia.wav', description: 'Empathetic, Clear, Calm, Confident', useCase: 'Customer service' },
  { value: 'helena', label: 'Helena (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-helena.wav', description: 'Caring, Natural, Positive, Friendly, Raspy', useCase: 'IVR, casual chat' },
  { value: 'hera', label: 'Hera (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-hera.wav', description: 'Smooth, Warm, Professional', useCase: 'Informative' },
  { value: 'hermes', label: 'Hermes (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-hermes.wav', description: 'Expressive, Engaging, Professional', useCase: 'Informative' },
  { value: 'hyperion', label: 'Hyperion (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-hyperion.wav', description: 'Caring, Warm, Empathetic', useCase: 'Interview' },
  { value: 'iris', label: 'Iris (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-iris.wav', description: 'Cheerful, Positive, Approachable', useCase: 'IVR, advertising, customer service' },
  { value: 'janus', label: 'Janus (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-janus.wav', description: 'Southern, Smooth, Trustworthy', useCase: 'Storytelling' },
  { value: 'juno', label: 'Juno (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-juno.wav', description: 'Natural, Engaging, Melodic, Breathy', useCase: 'Interview' },
  { value: 'jupiter', label: 'Jupiter (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-jupiter.wav', description: 'Expressive, Knowledgeable, Baritone', useCase: 'Informative' },
  { value: 'luna', label: 'Luna (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-luna.wav', description: 'Friendly, Natural, Engaging', useCase: 'IVR' },
  { value: 'mars', label: 'Mars (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-mars.wav', description: 'Smooth, Patient, Trustworthy, Baritone', useCase: 'Customer service' },
  { value: 'minerva', label: 'Minerva (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-minerva.wav', description: 'Positive, Friendly, Natural', useCase: 'Storytelling' },
  { value: 'neptune', label: 'Neptune (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-neptune.wav', description: 'Professional, Patient, Polite', useCase: 'Customer service' },
  { value: 'odysseus', label: 'Odysseus (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-odysseus.wav', description: 'Calm, Smooth, Comfortable, Professional', useCase: 'Advertising' },
  { value: 'ophelia', label: 'Ophelia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-ophelia.wav', description: 'Expressive, Enthusiastic, Cheerful', useCase: 'Interview' },
  { value: 'orion', label: 'Orion (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-orion.wav', description: 'Approachable, Comfortable, Calm, Polite', useCase: 'Informative' },
  { value: 'orpheus', label: 'Orpheus (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-orpheus.wav', description: 'Professional, Clear, Confident, Trustworthy', useCase: 'Customer service, storytelling' },
  { value: 'pandora', label: 'Pandora (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-pandora.wav', description: 'Smooth, Calm, Melodic, Breathy', useCase: 'IVR, informative' },
  { value: 'phoebe', label: 'Phoebe (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-phoebe.wav', description: 'Energetic, Warm, Casual', useCase: 'Customer service' },
  { value: 'pluto', label: 'Pluto (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-pluto.wav', description: 'Smooth, Calm, Empathetic, Baritone', useCase: 'Interview, storytelling' },
  { value: 'saturn', label: 'Saturn (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-saturn.wav', description: 'Knowledgeable, Confident, Baritone', useCase: 'Customer service' },
  { value: 'selene', label: 'Selene (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-selene.wav', description: 'Expressive, Engaging, Energetic', useCase: 'Informative' },
  { value: 'thalia', label: 'Thalia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-thalia.wav', description: 'Clear, Confident, Energetic, Enthusiastic', useCase: 'Casual chat, customer service, IVR' },
  { value: 'theia', label: 'Theia (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-theia.wav', description: 'Expressive, Polite, Sincere', useCase: 'Informative' },
  { value: 'vesta', label: 'Vesta (Deepgram)', provider: 'deepgram', gender: 'feminine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-vesta.wav', description: 'Natural, Expressive, Patient, Empathetic', useCase: 'Customer service, interview, storytelling' },
  { value: 'zeus', label: 'Zeus (Deepgram)', provider: 'deepgram', gender: 'masculine', audioUrl: 'https://static.deepgram.com/examples/Aura-2-zeus.wav', description: 'Deep, Trustworthy, Smooth', useCase: 'IVR' },
];

export const allVoices: VoiceConfig[] = [...vapiVoices, ...deepgramVoices];
